Config = {}

-- Appearance room (interior for character creation)
Config.AppearanceRoom = {
    coords = vector4(402.77, -997.07, -100.0, 180.0), -- Mission Row PD - Mugshot room (lowered to floor)
}

-- Camera settings
Config.Camera = {
    views = {
        face = {offset = vector3(0.0, 1.2, 0.65), fov = 30.0},
        body = {offset = vector3(0.0, 3.0, 0.2), fov = 50.0},
        legs = {offset = vector3(0.0, 3.0, -0.5), fov = 50.0}
    }
}

-- Hairstyles
Config.Hairstyles = {
    male = {
        {id = 0, label = "Bald", hint = "лысый"},
        {id = 1, label = "Short", hint = "короткие"},
        {id = 2, label = "Fade", hint = "фейд"},
        {id = 3, label = "Crew Cut", hint = "ёжик"},
        {id = 4, label = "Side Part", hint = "пробор"},
        {id = 5, label = "Slick Back", hint = "зачёс назад"},
        {id = 14, label = "Mullet", hint = "маллет"},
        {id = 15, label = "Long Hair", hint = "длинные"},
    },
    female = {
        {id = 0, label = "Bald", hint = "лысая"},
        {id = 1, label = "Ponytail", hint = "хвост"},
        {id = 2, label = "Short Bob", hint = "короткое каре"},
        {id = 3, label = "Long Straight", hint = "длинные прямые"},
        {id = 4, label = "Curly", hint = "кудрявые"},
        {id = 5, label = "Big Hair", hint = "большие волосы"},
        {id = 14, label = "Wavy", hint = "волнистые"},
    }
}

-- Hair colors
Config.HairColors = {
    {id = 0, label = "Black", hint = "чёрный"},
    {id = 1, label = "Dark Brown", hint = "тёмно-коричневый"},
    {id = 2, label = "Brown", hint = "коричневый"},
    {id = 3, label = "Light Brown", hint = "светло-коричневый"},
    {id = 4, label = "Blonde", hint = "блонд"},
    {id = 5, label = "Platinum Blonde", hint = "платиновый блонд"},
    {id = 6, label = "Red", hint = "рыжий"},
    {id = 7, label = "Auburn", hint = "каштановый"},
    {id = 8, label = "Gray", hint = "седой"},
}

-- Eye colors
Config.EyeColors = {
    {id = 0, label = "Green", hint = "зелёные"},
    {id = 1, label = "Blue", hint = "голубые"},
    {id = 2, label = "Brown", hint = "карие"},
    {id = 3, label = "Hazel", hint = "ореховые"},
    {id = 4, label = "Gray", hint = "серые"},
    {id = 5, label = "Light Blue", hint = "светло-голубые"},
}

-- Clothing options
Config.Clothing = {
    male = {
        torso = {
            {drawable = 15, texture = 0, label = "White T-Shirt", hint = "белая футболка"},
            {drawable = 15, texture = 1, label = "Black T-Shirt", hint = "чёрная футболка"},
            {drawable = 4, texture = 0, label = "Polo Shirt", hint = "поло"},
            {drawable = 12, texture = 0, label = "Leather Jacket", hint = "кожаная куртка"},
            {drawable = 13, texture = 0, label = "Hoodie", hint = "худи"},
            {drawable = 31, texture = 0, label = "Bomber Jacket", hint = "бомбер"},
            {drawable = 32, texture = 0, label = "Tracksuit Top", hint = "спортивка"},
            {drawable = 53, texture = 0, label = "Denim Jacket", hint = "джинсовка"},
        },
        legs = {
            {drawable = 4, texture = 0, label = "Black Jeans", hint = "чёрные джинсы"},
            {drawable = 4, texture = 1, label = "Blue Jeans", hint = "синие джинсы"},
            {drawable = 61, texture = 0, label = "Cargo Pants", hint = "карго"},
            {drawable = 24, texture = 0, label = "Shorts", hint = "шорты"},
            {drawable = 9, texture = 0, label = "Tracksuit Pants", hint = "спортивные штаны"},
            {drawable = 10, texture = 0, label = "Chinos", hint = "чиносы"},
        },
        shoes = {
            {drawable = 1, texture = 0, label = "White Sneakers", hint = "белые кроссовки"},
            {drawable = 1, texture = 1, label = "Black Sneakers", hint = "чёрные кроссовки"},
            {drawable = 4, texture = 0, label = "Boots", hint = "ботинки"},
            {drawable = 12, texture = 0, label = "Dress Shoes", hint = "туфли"},
            {drawable = 34, texture = 0, label = "High Tops", hint = "высокие кроссовки"},
            {drawable = 54, texture = 0, label = "Running Shoes", hint = "беговые кроссовки"},
        }
    },
    female = {
        torso = {
            {drawable = 15, texture = 0, label = "White T-Shirt", hint = "белая футболка"},
            {drawable = 15, texture = 1, label = "Black T-Shirt", hint = "чёрная футболка"},
            {drawable = 3, texture = 0, label = "Tank Top", hint = "майка"},
            {drawable = 9, texture = 0, label = "Blouse", hint = "блузка"},
            {drawable = 73, texture = 0, label = "Hoodie", hint = "худи"},
            {drawable = 251, texture = 0, label = "Leather Jacket", hint = "кожаная куртка"},
            {drawable = 233, texture = 0, label = "Denim Jacket", hint = "джинсовка"},
            {drawable = 7, texture = 0, label = "Dress", hint = "платье"},
        },
        legs = {
            {drawable = 15, texture = 0, label = "Black Jeans", hint = "чёрные джинсы"},
            {drawable = 15, texture = 1, label = "Blue Jeans", hint = "синие джинсы"},
            {drawable = 6, texture = 0, label = "Shorts", hint = "шорты"},
            {drawable = 7, texture = 0, label = "Skirt", hint = "юбка"},
            {drawable = 8, texture = 0, label = "Leggings", hint = "леггинсы"},
            {drawable = 44, texture = 0, label = "Cargo Pants", hint = "карго"},
        },
        shoes = {
            {drawable = 1, texture = 0, label = "White Sneakers", hint = "белые кроссовки"},
            {drawable = 1, texture = 1, label = "Black Sneakers", hint = "чёрные кроссовки"},
            {drawable = 6, texture = 0, label = "Heels", hint = "каблуки"},
            {drawable = 35, texture = 0, label = "Boots", hint = "ботинки"},
            {drawable = 52, texture = 0, label = "Flats", hint = "балетки"},
            {drawable = 62, texture = 0, label = "High Tops", hint = "высокие кроссовки"},
        }
    }
}

-- Default clothing (fallback)
Config.DefaultClothing = {
    male = {
        torso = {drawable = 15, texture = 0},
        legs = {drawable = 4, texture = 0},
        shoes = {drawable = 1, texture = 0},
        arms = {drawable = 0, texture = 0}
    },
    female = {
        torso = {drawable = 15, texture = 0},
        legs = {drawable = 15, texture = 0},
        shoes = {drawable = 1, texture = 0},
        arms = {drawable = 0, texture = 0}
    }
}
