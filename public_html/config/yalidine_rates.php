<?php

/**
 * Fallback Yalidine tariff table (in DZD) and Stop-Desk directory for all 58 Algerian Wilayas.
 *
 * Used by App\Services\DzshipYalidineService when YALIDINE_STUB_MODE=true or if the
 * upstream DZBuild dzship API (https://freeship.dzbuild.com) is unreachable.
 *
 * Only Yalidine (courier: "yalidine") is supported.
 */
return [
    'base_url' => env('DZSHIP_BASE_URL', 'https://freeship.dzbuild.com'),
    'courier' => 'yalidine',
    'stub_mode' => filter_var(env('YALIDINE_STUB_MODE', true), FILTER_VALIDATE_BOOLEAN),
    'cache_ttl_seconds' => 60 * 60 * 24 * 7, // 7 days

    // All 58 Algerian Wilayas (code 1..58) with French & Arabic names and fallback Yalidine rates from Algiers (16)
    'wilayas' => [
        1 => ['code' => 1, 'name_fr' => 'Adrar', 'name_ar' => 'أدرار', 'zone' => 'south', 'home_dzd' => 1100, 'stop_desk_dzd' => 700, 'days' => 4],
        2 => ['code' => 2, 'name_fr' => 'Chlef', 'name_ar' => 'الشلف', 'zone' => 'north_west', 'home_dzd' => 600, 'stop_desk_dzd' => 400, 'days' => 2],
        3 => ['code' => 3, 'name_fr' => 'Laghouat', 'name_ar' => 'الأغواط', 'zone' => 'highlands', 'home_dzd' => 850, 'stop_desk_dzd' => 550, 'days' => 3],
        4 => ['code' => 4, 'name_fr' => 'Oum El Bouaghi', 'name_ar' => 'أم البواقي', 'zone' => 'north_east', 'home_dzd' => 700, 'stop_desk_dzd' => 450, 'days' => 2],
        5 => ['code' => 5, 'name_fr' => 'Batna', 'name_ar' => 'باتنة', 'zone' => 'north_east', 'home_dzd' => 700, 'stop_desk_dzd' => 450, 'days' => 2],
        6 => ['code' => 6, 'name_fr' => 'Béjaïa', 'name_ar' => 'بجاية', 'zone' => 'north_center', 'home_dzd' => 600, 'stop_desk_dzd' => 400, 'days' => 2],
        7 => ['code' => 7, 'name_fr' => 'Biskra', 'name_ar' => 'بسكرة', 'zone' => 'highlands', 'home_dzd' => 800, 'stop_desk_dzd' => 500, 'days' => 3],
        8 => ['code' => 8, 'name_fr' => 'Béchar', 'name_ar' => 'بشار', 'zone' => 'south', 'home_dzd' => 1050, 'stop_desk_dzd' => 650, 'days' => 4],
        9 => ['code' => 9, 'name_fr' => 'Blida', 'name_ar' => 'البليدة', 'zone' => 'north_center', 'home_dzd' => 500, 'stop_desk_dzd' => 350, 'days' => 1],
        10 => ['code' => 10, 'name_fr' => 'Bouira', 'name_ar' => 'البويرة', 'zone' => 'north_center', 'home_dzd' => 550, 'stop_desk_dzd' => 350, 'days' => 1],
        11 => ['code' => 11, 'name_fr' => 'Tamanrasset', 'name_ar' => 'تمنراست', 'zone' => 'deep_south', 'home_dzd' => 1400, 'stop_desk_dzd' => 900, 'days' => 5],
        12 => ['code' => 12, 'name_fr' => 'Tébessa', 'name_ar' => 'تبسة', 'zone' => 'north_east', 'home_dzd' => 750, 'stop_desk_dzd' => 450, 'days' => 2],
        13 => ['code' => 13, 'name_fr' => 'Tlemcen', 'name_ar' => 'تلمسان', 'zone' => 'north_west', 'home_dzd' => 700, 'stop_desk_dzd' => 450, 'days' => 2],
        14 => ['code' => 14, 'name_fr' => 'Tiaret', 'name_ar' => 'تيارت', 'zone' => 'highlands', 'home_dzd' => 700, 'stop_desk_dzd' => 450, 'days' => 2],
        15 => ['code' => 15, 'name_fr' => 'Tizi Ouzou', 'name_ar' => 'تيزي وزو', 'zone' => 'north_center', 'home_dzd' => 550, 'stop_desk_dzd' => 350, 'days' => 1],
        16 => ['code' => 16, 'name_fr' => 'Alger', 'name_ar' => 'الجزائر', 'zone' => 'north_center', 'home_dzd' => 400, 'stop_desk_dzd' => 300, 'days' => 1],
        17 => ['code' => 17, 'name_fr' => 'Djelfa', 'name_ar' => 'الجلفة', 'zone' => 'highlands', 'home_dzd' => 800, 'stop_desk_dzd' => 500, 'days' => 2],
        18 => ['code' => 18, 'name_fr' => 'Jijel', 'name_ar' => 'جيجل', 'zone' => 'north_east', 'home_dzd' => 650, 'stop_desk_dzd' => 400, 'days' => 2],
        19 => ['code' => 19, 'name_fr' => 'Sétif', 'name_ar' => 'سطيف', 'zone' => 'north_east', 'home_dzd' => 650, 'stop_desk_dzd' => 400, 'days' => 2],
        20 => ['code' => 20, 'name_fr' => 'Saïda', 'name_ar' => 'سعيدة', 'zone' => 'north_west', 'home_dzd' => 750, 'stop_desk_dzd' => 450, 'days' => 2],
        21 => ['code' => 21, 'name_fr' => 'Skikda', 'name_ar' => 'سكيكدة', 'zone' => 'north_east', 'home_dzd' => 700, 'stop_desk_dzd' => 450, 'days' => 2],
        22 => ['code' => 22, 'name_fr' => 'Sidi Bel Abbès', 'name_ar' => 'سيدي بلعباس', 'zone' => 'north_west', 'home_dzd' => 700, 'stop_desk_dzd' => 450, 'days' => 2],
        23 => ['code' => 23, 'name_fr' => 'Annaba', 'name_ar' => 'عنابة', 'zone' => 'north_east', 'home_dzd' => 700, 'stop_desk_dzd' => 450, 'days' => 2],
        24 => ['code' => 24, 'name_fr' => 'Guelma', 'name_ar' => 'قالمة', 'zone' => 'north_east', 'home_dzd' => 700, 'stop_desk_dzd' => 450, 'days' => 2],
        25 => ['code' => 25, 'name_fr' => 'Constantine', 'name_ar' => 'قسنطينة', 'zone' => 'north_east', 'home_dzd' => 650, 'stop_desk_dzd' => 400, 'days' => 2],
        26 => ['code' => 26, 'name_fr' => 'Médéa', 'name_ar' => 'المدية', 'zone' => 'north_center', 'home_dzd' => 550, 'stop_desk_dzd' => 350, 'days' => 1],
        27 => ['code' => 27, 'name_fr' => 'Mostaganem', 'name_ar' => 'مستغانم', 'zone' => 'north_west', 'home_dzd' => 650, 'stop_desk_dzd' => 400, 'days' => 2],
        28 => ['code' => 28, 'name_fr' => "M'Sila", 'name_ar' => 'المسيلة', 'zone' => 'highlands', 'home_dzd' => 700, 'stop_desk_dzd' => 450, 'days' => 2],
        29 => ['code' => 29, 'name_fr' => 'Mascara', 'name_ar' => 'معسكر', 'zone' => 'north_west', 'home_dzd' => 700, 'stop_desk_dzd' => 450, 'days' => 2],
        30 => ['code' => 30, 'name_fr' => 'Ouargla', 'name_ar' => 'ورقلة', 'zone' => 'south', 'home_dzd' => 950, 'stop_desk_dzd' => 600, 'days' => 3],
        31 => ['code' => 31, 'name_fr' => 'Oran', 'name_ar' => 'وهران', 'zone' => 'north_west', 'home_dzd' => 650, 'stop_desk_dzd' => 400, 'days' => 2],
        32 => ['code' => 32, 'name_fr' => 'El Bayadh', 'name_ar' => 'البيض', 'zone' => 'highlands', 'home_dzd' => 900, 'stop_desk_dzd' => 550, 'days' => 3],
        33 => ['code' => 33, 'name_fr' => 'Illizi', 'name_ar' => 'إليزي', 'zone' => 'deep_south', 'home_dzd' => 1450, 'stop_desk_dzd' => 950, 'days' => 5],
        34 => ['code' => 34, 'name_fr' => 'Bordj Bou Arréridj', 'name_ar' => 'برج بوعريريج', 'zone' => 'north_east', 'home_dzd' => 600, 'stop_desk_dzd' => 400, 'days' => 2],
        35 => ['code' => 35, 'name_fr' => 'Boumerdès', 'name_ar' => 'بومرداس', 'zone' => 'north_center', 'home_dzd' => 500, 'stop_desk_dzd' => 350, 'days' => 1],
        36 => ['code' => 36, 'name_fr' => 'El Tarf', 'name_ar' => 'الطارف', 'zone' => 'north_east', 'home_dzd' => 750, 'stop_desk_dzd' => 450, 'days' => 2],
        37 => ['code' => 37, 'name_fr' => 'Tindouf', 'name_ar' => 'تندوف', 'zone' => 'deep_south', 'home_dzd' => 1450, 'stop_desk_dzd' => 950, 'days' => 5],
        38 => ['code' => 38, 'name_fr' => 'Tissemsilt', 'name_ar' => 'تيسمسيلت', 'zone' => 'highlands', 'home_dzd' => 700, 'stop_desk_dzd' => 450, 'days' => 2],
        39 => ['code' => 39, 'name_fr' => 'El Oued', 'name_ar' => 'الوادي', 'zone' => 'south', 'home_dzd' => 900, 'stop_desk_dzd' => 550, 'days' => 3],
        40 => ['code' => 40, 'name_fr' => 'Khenchela', 'name_ar' => 'خنشلة', 'zone' => 'north_east', 'home_dzd' => 750, 'stop_desk_dzd' => 450, 'days' => 2],
        41 => ['code' => 41, 'name_fr' => 'Souk Ahras', 'name_ar' => 'سوق أهراس', 'zone' => 'north_east', 'home_dzd' => 750, 'stop_desk_dzd' => 450, 'days' => 2],
        42 => ['code' => 42, 'name_fr' => 'Tipaza', 'name_ar' => 'تيبازة', 'zone' => 'north_center', 'home_dzd' => 500, 'stop_desk_dzd' => 350, 'days' => 1],
        43 => ['code' => 43, 'name_fr' => 'Mila', 'name_ar' => 'ميلة', 'zone' => 'north_east', 'home_dzd' => 700, 'stop_desk_dzd' => 450, 'days' => 2],
        44 => ['code' => 44, 'name_fr' => 'Aïn Defla', 'name_ar' => 'عين الدفلى', 'zone' => 'north_center', 'home_dzd' => 600, 'stop_desk_dzd' => 400, 'days' => 2],
        45 => ['code' => 45, 'name_fr' => 'Naâma', 'name_ar' => 'النعامة', 'zone' => 'highlands', 'home_dzd' => 900, 'stop_desk_dzd' => 550, 'days' => 3],
        46 => ['code' => 46, 'name_fr' => 'Aïn Témouchent', 'name_ar' => 'عين تموشنت', 'zone' => 'north_west', 'home_dzd' => 700, 'stop_desk_dzd' => 450, 'days' => 2],
        47 => ['code' => 47, 'name_fr' => 'Ghardaïa', 'name_ar' => 'غرداية', 'zone' => 'south', 'home_dzd' => 900, 'stop_desk_dzd' => 550, 'days' => 3],
        48 => ['code' => 48, 'name_fr' => 'Relizane', 'name_ar' => 'غليزان', 'zone' => 'north_west', 'home_dzd' => 650, 'stop_desk_dzd' => 400, 'days' => 2],
        49 => ['code' => 49, 'name_fr' => 'Timimoun', 'name_ar' => 'تيميمون', 'zone' => 'south', 'home_dzd' => 1150, 'stop_desk_dzd' => 750, 'days' => 4],
        50 => ['code' => 50, 'name_fr' => 'Bordj Badji Mokhtar', 'name_ar' => 'برج باجي مختار', 'zone' => 'deep_south', 'home_dzd' => 1500, 'stop_desk_dzd' => 950, 'days' => 5],
        51 => ['code' => 51, 'name_fr' => 'Ouled Djellal', 'name_ar' => 'أولاد جلال', 'zone' => 'south', 'home_dzd' => 850, 'stop_desk_dzd' => 550, 'days' => 3],
        52 => ['code' => 52, 'name_fr' => 'Béni Abbès', 'name_ar' => 'بني عباس', 'zone' => 'south', 'home_dzd' => 1100, 'stop_desk_dzd' => 700, 'days' => 4],
        53 => ['code' => 53, 'name_fr' => 'In Salah', 'name_ar' => 'عين صالح', 'zone' => 'deep_south', 'home_dzd' => 1350, 'stop_desk_dzd' => 850, 'days' => 5],
        54 => ['code' => 54, 'name_fr' => 'In Guezzam', 'name_ar' => 'عين قزام', 'zone' => 'deep_south', 'home_dzd' => 1500, 'stop_desk_dzd' => 950, 'days' => 5],
        55 => ['code' => 55, 'name_fr' => 'Touggourt', 'name_ar' => 'تقرت', 'zone' => 'south', 'home_dzd' => 900, 'stop_desk_dzd' => 550, 'days' => 3],
        56 => ['code' => 56, 'name_fr' => 'Djanet', 'name_ar' => 'جانت', 'zone' => 'deep_south', 'home_dzd' => 1500, 'stop_desk_dzd' => 950, 'days' => 5],
        57 => ['code' => 57, 'name_fr' => "El M'Ghair", 'name_ar' => 'المغير', 'zone' => 'south', 'home_dzd' => 900, 'stop_desk_dzd' => 550, 'days' => 3],
        58 => ['code' => 58, 'name_fr' => 'El Meniaa', 'name_ar' => 'المنيعة', 'zone' => 'south', 'home_dzd' => 1000, 'stop_desk_dzd' => 650, 'days' => 4],
    ],

    // Popular Yalidine Stop-Desk branches (any wilaya not explicitly listed gets a default central bureau)
    'desks' => [
        6 => [
            ['id' => '60101', 'name' => 'Agence Yalidine Béjaïa Centre', 'communeName' => 'Bejaia', 'address' => 'Cité Somacob, Béjaïa'],
            ['id' => '60201', 'name' => 'Agence Yalidine Akbou', 'communeName' => 'Akbou', 'address' => 'Centre-ville, Akbou'],
        ],
        9 => [
            ['id' => '90101', 'name' => 'Agence Yalidine Blida Centre', 'communeName' => 'Blida', 'address' => 'Boulevard Larbi Tebessi, Blida'],
            ['id' => '90201', 'name' => 'Agence Yalidine Boufarik', 'communeName' => 'Boufarik', 'address' => 'Centre-ville, Boufarik'],
        ],
        13 => [
            ['id' => '130101', 'name' => 'Agence Yalidine Tlemcen Kiffane', 'communeName' => 'Tlemcen', 'address' => 'Quartier Kiffane, Tlemcen'],
            ['id' => '130201', 'name' => 'Agence Yalidine Maghnia', 'communeName' => 'Maghnia', 'address' => 'Centre-ville, Maghnia'],
        ],
        15 => [
            ['id' => '150101', 'name' => 'Agence Yalidine Tizi Ouzou Nouvelle Ville', 'communeName' => 'Tizi Ouzou', 'address' => 'Nouvelle Ville, Tizi Ouzou'],
            ['id' => '150201', 'name' => 'Agence Yalidine Azazga', 'communeName' => 'Azazga', 'address' => 'Centre-ville, Azazga'],
        ],
        16 => [
            ['id' => '160101', 'name' => 'Agence Yalidine Alger Centre (Didouche)', 'communeName' => 'Alger Centre', 'address' => 'Rue Didouche Mourad, Alger Centre'],
            ['id' => '161101', 'name' => 'Agence Yalidine Bab Ezzouar', 'communeName' => 'Bab Ezzouar', 'address' => 'Cité 5 Juillet, Bab Ezzouar'],
            ['id' => '162401', 'name' => 'Agence Yalidine Bir Mourad Raïs', 'communeName' => 'Bir Mourad Rais', 'address' => 'Bir Mourad Raïs, Alger'],
            ['id' => '163501', 'name' => 'Agence Yalidine Chéraga', 'communeName' => 'Cheraga', 'address' => 'Centre Commercial, Chéraga'],
        ],
        19 => [
            ['id' => '190101', 'name' => 'Agence Yalidine Sétif Centre', 'communeName' => 'Setif', 'address' => 'Cité Maabouda, Sétif'],
            ['id' => '190201', 'name' => 'Agence Yalidine El Eulma', 'communeName' => 'El Eulma', 'address' => 'Rue de Dubaï, El Eulma'],
        ],
        23 => [
            ['id' => '230101', 'name' => 'Agence Yalidine Annaba Centre', 'communeName' => 'Annaba', 'address' => 'Cours de la Révolution, Annaba'],
            ['id' => '230201', 'name' => 'Agence Yalidine El Bouni', 'communeName' => 'El Bouni', 'address' => 'Centre-ville, El Bouni'],
        ],
        25 => [
            ['id' => '250101', 'name' => 'Agence Yalidine Constantine Zouaghi', 'communeName' => 'Constantine', 'address' => 'Zouaghi Slimane, Constantine'],
            ['id' => '250201', 'name' => 'Agence Yalidine Ali Mendjeli', 'communeName' => 'El Khroub', 'address' => 'Nouvelle Ville Ali Mendjeli'],
        ],
        31 => [
            ['id' => '310101', 'name' => 'Agence Yalidine Oran Millénium', 'communeName' => 'Bir El Djir', 'address' => 'Cité Millénium, Bir El Djir'],
            ['id' => '310201', 'name' => 'Agence Yalidine Oran Centre', 'communeName' => 'Oran', 'address' => 'Boulevard de la Soummam, Oran'],
            ['id' => '310301', 'name' => 'Agence Yalidine Es Sénia', 'communeName' => 'Es Senia', 'address' => 'Centre-ville, Es Sénia'],
        ],
        35 => [
            ['id' => '350101', 'name' => 'Agence Yalidine Boumerdès Centre', 'communeName' => 'Boumerdes', 'address' => 'Cité 800 Logements, Boumerdès'],
        ],
        42 => [
            ['id' => '420101', 'name' => 'Agence Yalidine Tipaza Centre', 'communeName' => 'Tipaza', 'address' => 'Centre-ville, Tipaza'],
            ['id' => '420201', 'name' => 'Agence Yalidine Koléa', 'communeName' => 'Kolea', 'address' => 'Centre-ville, Koléa'],
        ],
    ],
];
