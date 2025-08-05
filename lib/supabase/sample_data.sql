-- Helper function to insert users to auth.users
CREATE OR REPLACE FUNCTION insert_user_to_auth(
    email text,
    password text
) RETURNS UUID AS $$
DECLARE
  user_id uuid;
  encrypted_pw text;
BEGIN
  user_id := gen_random_uuid();
  encrypted_pw := crypt(password, gen_salt('bf'));
  
  INSERT INTO auth.users
    (instance_id, id, aud, role, email, encrypted_password, email_confirmed_at, recovery_sent_at, last_sign_in_at, raw_app_meta_data, raw_user_meta_data, created_at, updated_at, confirmation_token, email_change, email_change_token_new, recovery_token)
  VALUES
    (gen_random_uuid(), user_id, 'authenticated', 'authenticated', email, encrypted_pw, '2023-05-03 19:41:43.585805+00', '2023-04-22 13:10:03.275387+00', '2023-04-22 13:10:31.458239+00', '{"provider":"email","providers":["email"]}', '{}', '2023-05-03 19:41:43.580424+00', '2023-05-03 19:41:43.585948+00', '', '', '', '');
  
  INSERT INTO auth.identities (provider_id, user_id, identity_data, provider, last_sign_in_at, created_at, updated_at)
  VALUES
    (gen_random_uuid(), user_id, format('{"sub":"%s","email":"%s"}', user_id::text, email)::jsonb, 'email', '2023-05-03 19:41:43.582456+00', '2023-05-03 19:41:43.582497+00', '2023-05-03 19:41:43.582497+00');
  
  RETURN user_id;
END;
$$ LANGUAGE plpgsql;

-- Insert sample users to auth.users and get their IDs
DO $$
DECLARE
    user1_id uuid;
    user2_id uuid;
    user3_id uuid;
BEGIN
    -- Insert users to auth.users
    user1_id := insert_user_to_auth('jean.mboma@email.com', 'password123');
    user2_id := insert_user_to_auth('marie.nguema@email.com', 'password123');
    user3_id := insert_user_to_auth('paul.biya@email.com', 'password123');

    -- Insert users data
    INSERT INTO users (id, email, phone, eneo_client_id, full_name, meter_address) VALUES
    (user1_id, 'jean.mboma@email.com', '+237677123456', 'ENEO001234', 'Jean Mboma', 'Quartier Bastos, Yaoundé'),
    (user2_id, 'marie.nguema@email.com', '+237677654321', 'ENEO005678', 'Marie Nguema', 'Akwa, Douala'),
    (user3_id, 'paul.biya@email.com', '+237677987654', 'ENEO009876', 'Paul Biya', 'New Bell, Douala');

    -- Insert contracts
    INSERT INTO contracts (user_id, contract_number, start_date, end_date, status, meter_type) VALUES
    (user1_id, 'CT2024001', '2024-01-15', NULL, 'active', 'prepaid'),
    (user1_id, 'CT2023001', '2023-01-15', '2023-12-31', 'expired', 'postpaid'),
    (user2_id, 'CT2024002', '2024-02-01', NULL, 'active', 'postpaid'),
    (user3_id, 'CT2024003', '2024-01-01', NULL, 'active', 'prepaid');

    -- Insert consumption readings (last 30 days)
    INSERT INTO consumption_readings (user_id, reading_date, kwh_consumed, cost_fcfa, meter_reading, local_average_kwh) VALUES
    -- User 1 data
    (user1_id, CURRENT_DATE - INTERVAL '29 days', 12.5, 6250, 1012.5, 15.2),
    (user1_id, CURRENT_DATE - INTERVAL '28 days', 15.3, 7650, 1027.8, 15.5),
    (user1_id, CURRENT_DATE - INTERVAL '27 days', 18.7, 9350, 1046.5, 16.1),
    (user1_id, CURRENT_DATE - INTERVAL '26 days', 14.2, 7100, 1060.7, 15.8),
    (user1_id, CURRENT_DATE - INTERVAL '25 days', 16.8, 8400, 1077.5, 16.3),
    (user1_id, CURRENT_DATE - INTERVAL '24 days', 13.9, 6950, 1091.4, 15.9),
    (user1_id, CURRENT_DATE - INTERVAL '23 days', 17.4, 8700, 1108.8, 16.5),
    (user1_id, CURRENT_DATE - INTERVAL '22 days', 19.2, 9600, 1128.0, 17.2),
    (user1_id, CURRENT_DATE - INTERVAL '21 days', 15.6, 7800, 1143.6, 16.8),
    (user1_id, CURRENT_DATE - INTERVAL '20 days', 14.1, 7050, 1157.7, 16.2),
    
    -- User 2 data
    (user2_id, CURRENT_DATE - INTERVAL '29 days', 22.3, 11150, 2022.3, 18.5),
    (user2_id, CURRENT_DATE - INTERVAL '28 days', 25.7, 12850, 2048.0, 19.2),
    (user2_id, CURRENT_DATE - INTERVAL '27 days', 28.4, 14200, 2076.4, 20.1),
    (user2_id, CURRENT_DATE - INTERVAL '26 days', 24.8, 12400, 2101.2, 19.8),
    (user2_id, CURRENT_DATE - INTERVAL '25 days', 26.9, 13450, 2128.1, 20.3),
    (user2_id, CURRENT_DATE - INTERVAL '24 days', 23.5, 11750, 2151.6, 19.6),
    (user2_id, CURRENT_DATE - INTERVAL '23 days', 27.8, 13900, 2179.4, 20.8),
    (user2_id, CURRENT_DATE - INTERVAL '22 days', 30.1, 15050, 2209.5, 21.5),
    (user2_id, CURRENT_DATE - INTERVAL '21 days', 26.2, 13100, 2235.7, 20.9),
    (user2_id, CURRENT_DATE - INTERVAL '20 days', 25.0, 12500, 2260.7, 20.4),
    
    -- User 3 data
    (user3_id, CURRENT_DATE - INTERVAL '29 days', 8.9, 4450, 508.9, 12.3),
    (user3_id, CURRENT_DATE - INTERVAL '28 days', 10.2, 5100, 519.1, 12.8),
    (user3_id, CURRENT_DATE - INTERVAL '27 days', 11.8, 5900, 530.9, 13.2),
    (user3_id, CURRENT_DATE - INTERVAL '26 days', 9.7, 4850, 540.6, 12.9),
    (user3_id, CURRENT_DATE - INTERVAL '25 days', 12.4, 6200, 553.0, 13.5),
    (user3_id, CURRENT_DATE - INTERVAL '24 days', 8.6, 4300, 561.6, 12.7),
    (user3_id, CURRENT_DATE - INTERVAL '23 days', 11.3, 5650, 572.9, 13.1),
    (user3_id, CURRENT_DATE - INTERVAL '22 days', 13.7, 6850, 586.6, 13.8),
    (user3_id, CURRENT_DATE - INTERVAL '21 days', 10.8, 5400, 597.4, 13.3),
    (user3_id, CURRENT_DATE - INTERVAL '20 days', 9.4, 4700, 606.8, 12.9);

    -- Insert bills
    INSERT INTO bills (user_id, bill_number, amount_fcfa, due_date, issue_date, status, consumption_kwh, service_charge_fcfa, tax_fcfa) VALUES
    (user1_id, 'BILL202401001', 85750, CURRENT_DATE + INTERVAL '10 days', CURRENT_DATE - INTERVAL '20 days', 'unpaid', 171.5, 5000, 12862.5),
    (user1_id, 'BILL202312001', 72300, CURRENT_DATE - INTERVAL '45 days', CURRENT_DATE - INTERVAL '65 days', 'paid', 144.6, 5000, 10845),
    (user2_id, 'BILL202401002', 145200, CURRENT_DATE + INTERVAL '15 days', CURRENT_DATE - INTERVAL '15 days', 'unpaid', 290.4, 8000, 21780),
    (user2_id, 'BILL202312002', 138900, CURRENT_DATE - INTERVAL '30 days', CURRENT_DATE - INTERVAL '50 days', 'paid', 277.8, 8000, 20835),
    (user3_id, 'BILL202401003', 54650, CURRENT_DATE + INTERVAL '8 days', CURRENT_DATE - INTERVAL '22 days', 'unpaid', 109.3, 3000, 8197.5);

    -- Insert payments
    INSERT INTO payments (user_id, bill_id, amount_fcfa, payment_method, payment_provider, transaction_id, status, payment_date) VALUES
    (user1_id, (SELECT id FROM bills WHERE bill_number = 'BILL202312001'), 72300, 'mobile_money', 'MTN MoMo', 'TXN20231215001', 'completed', CURRENT_DATE - INTERVAL '40 days'),
    (user2_id, (SELECT id FROM bills WHERE bill_number = 'BILL202312002'), 138900, 'credit_card', 'Visa', 'TXN20231220002', 'completed', CURRENT_DATE - INTERVAL '25 days');

    -- Insert alerts
    INSERT INTO alerts (user_id, alert_type, title, message, threshold_value, threshold_type, is_active, triggered_at) VALUES
    (user1_id, 'bill_due', 'Facture à échéance', 'Votre facture de 85,750 FCFA arrive à échéance dans 10 jours', 85750, 'amount_fcfa', true, CURRENT_DATE - INTERVAL '1 day'),
    (user1_id, 'consumption_spike', 'Consommation élevée', 'Votre consommation a augmenté de 25% par rapport à la semaine dernière', 25, 'percentage', true, CURRENT_DATE - INTERVAL '2 days'),
    (user2_id, 'custom_threshold', 'Seuil atteint', 'Vous avez atteint votre seuil personnalisé de 50,000 FCFA', 50000, 'amount_fcfa', true, CURRENT_DATE - INTERVAL '3 days'),
    (user2_id, 'bill_due', 'Facture à échéance', 'Votre facture de 145,200 FCFA arrive à échéance dans 15 jours', 145200, 'amount_fcfa', true, CURRENT_DATE),
    (user3_id, 'payment_reminder', 'Rappel de paiement', 'N\'oubliez pas de payer votre facture de 54,650 FCFA', 54650, 'amount_fcfa', true, CURRENT_DATE - INTERVAL '1 day');

    -- Insert user preferences
    INSERT INTO user_preferences (user_id, monthly_budget_fcfa, consumption_alert_percentage, custom_threshold_fcfa, enable_push_notifications, enable_email_notifications, preferred_language) VALUES
    (user1_id, 100000, 20, 50000, true, true, 'fr'),
    (user2_id, 180000, 15, 75000, true, false, 'fr'),
    (user3_id, 80000, 25, 40000, false, true, 'en');

    -- Insert outages
    INSERT INTO outages (region, scheduled_start, scheduled_end, reason, status, affected_areas) VALUES
    ('Yaoundé', CURRENT_DATE + INTERVAL '2 days' + INTERVAL '8 hours', CURRENT_DATE + INTERVAL '2 days' + INTERVAL '14 hours', 'Maintenance préventive des transformateurs', 'scheduled', ARRAY['Bastos', 'Melen', 'Essos']),
    ('Douala', CURRENT_DATE + INTERVAL '5 days' + INTERVAL '6 hours', CURRENT_DATE + INTERVAL '5 days' + INTERVAL '18 hours', 'Réparation ligne haute tension', 'scheduled', ARRAY['Akwa', 'Bonanjo', 'New Bell']),
    ('Bafoussam', CURRENT_DATE - INTERVAL '1 day' + INTERVAL '9 hours', CURRENT_DATE - INTERVAL '1 day' + INTERVAL '16 hours', 'Maintenance réseau', 'completed', ARRAY['Centre ville', 'Famla']);

END $$;