-- Create users table with foreign key to auth.users
CREATE TABLE users (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    email TEXT UNIQUE NOT NULL,
    phone TEXT,
    eneo_client_id TEXT UNIQUE,
    full_name TEXT,
    meter_address TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create contracts table for user contract history
CREATE TABLE contracts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    contract_number TEXT UNIQUE NOT NULL,
    start_date DATE NOT NULL,
    end_date DATE,
    status TEXT NOT NULL DEFAULT 'active' CHECK (status IN ('active', 'expired', 'cancelled')),
    meter_type TEXT NOT NULL DEFAULT 'prepaid' CHECK (meter_type IN ('prepaid', 'postpaid')),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create consumption_readings table for daily consumption data
CREATE TABLE consumption_readings (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    reading_date DATE NOT NULL,
    kwh_consumed DECIMAL(10,2) NOT NULL DEFAULT 0,
    cost_fcfa DECIMAL(12,2) NOT NULL DEFAULT 0,
    meter_reading DECIMAL(10,2),
    local_average_kwh DECIMAL(10,2),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(user_id, reading_date)
);

-- Create bills table for electricity bills
CREATE TABLE bills (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    bill_number TEXT UNIQUE NOT NULL,
    amount_fcfa DECIMAL(12,2) NOT NULL,
    due_date DATE NOT NULL,
    issue_date DATE NOT NULL,
    status TEXT NOT NULL DEFAULT 'unpaid' CHECK (status IN ('paid', 'unpaid', 'overdue', 'partial')),
    consumption_kwh DECIMAL(10,2) NOT NULL,
    service_charge_fcfa DECIMAL(10,2) DEFAULT 0,
    tax_fcfa DECIMAL(10,2) DEFAULT 0,
    late_fee_fcfa DECIMAL(10,2) DEFAULT 0,
    pdf_url TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create payments table for payment history
CREATE TABLE payments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    bill_id UUID NOT NULL REFERENCES bills(id) ON DELETE CASCADE,
    amount_fcfa DECIMAL(12,2) NOT NULL,
    payment_method TEXT NOT NULL CHECK (payment_method IN ('mobile_money', 'credit_card', 'bank_transfer', 'cash')),
    payment_provider TEXT,
    transaction_id TEXT UNIQUE,
    status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'completed', 'failed', 'cancelled')),
    payment_date TIMESTAMP WITH TIME ZONE NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create alerts table for user notifications and alerts
CREATE TABLE alerts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    alert_type TEXT NOT NULL CHECK (alert_type IN ('consumption_spike', 'bill_due', 'payment_reminder', 'outage_scheduled', 'custom_threshold')),
    title TEXT NOT NULL,
    message TEXT NOT NULL,
    threshold_value DECIMAL(12,2),
    threshold_type TEXT CHECK (threshold_type IN ('amount_fcfa', 'consumption_kwh', 'percentage')),
    is_active BOOLEAN DEFAULT true,
    is_read BOOLEAN DEFAULT false,
    triggered_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create user_preferences table for personalized settings
CREATE TABLE user_preferences (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    monthly_budget_fcfa DECIMAL(12,2),
    consumption_alert_percentage INTEGER DEFAULT 20,
    custom_threshold_fcfa DECIMAL(12,2),
    enable_push_notifications BOOLEAN DEFAULT true,
    enable_email_notifications BOOLEAN DEFAULT true,
    enable_sms_notifications BOOLEAN DEFAULT false,
    preferred_language TEXT DEFAULT 'fr' CHECK (preferred_language IN ('fr', 'en')),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(user_id)
);

-- Create outages table for scheduled power outages
CREATE TABLE outages (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    region TEXT NOT NULL,
    scheduled_start TIMESTAMP WITH TIME ZONE NOT NULL,
    scheduled_end TIMESTAMP WITH TIME ZONE NOT NULL,
    actual_start TIMESTAMP WITH TIME ZONE,
    actual_end TIMESTAMP WITH TIME ZONE,
    reason TEXT,
    status TEXT NOT NULL DEFAULT 'scheduled' CHECK (status IN ('scheduled', 'ongoing', 'completed', 'cancelled')),
    affected_areas TEXT[],
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create indexes for better performance
CREATE INDEX idx_consumption_readings_user_date ON consumption_readings(user_id, reading_date DESC);
CREATE INDEX idx_bills_user_status ON bills(user_id, status);
CREATE INDEX idx_bills_due_date ON bills(due_date);
CREATE INDEX idx_payments_user_date ON payments(user_id, payment_date DESC);
CREATE INDEX idx_alerts_user_active ON alerts(user_id, is_active, created_at DESC);
CREATE INDEX idx_outages_region_date ON outages(region, scheduled_start);

-- Create functions for automatic timestamp updates
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Create triggers for updated_at columns
CREATE TRIGGER update_users_updated_at BEFORE UPDATE ON users
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_user_preferences_updated_at BEFORE UPDATE ON user_preferences
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();