--[[
    Шаблон листа персонажа (D&D 5e) для Tabletop Simulator
    Автор оригинала: MrStump
    Кастомизация Scripted_Sheet_DnD5e_PTv1_6: Nymeros
    Общий рефакторинг и новые фичи: Ohar
    Подключение к интерактивной книге заклинаний: Daelin

    [ИСПРАВЛЕНО] В исходном варианте все ~240 констант вида *_ID были
    объявлены как `local` на верхнем уровне файла — вместе с остальными
    локальными переменными их набиралось больше 200, а Lua (в т.ч. движок
    TTS) физически не даёт функции/чанку иметь больше 200 локальных
    переменных одновременно. Из-за этого скрипт в исходном виде не смог бы
    загрузиться в игре вообще (ошибка компиляции). Исправлено простым
    способом — константы-идентификаторы стали глобальными переменными
    (убрано слово `local` в их объявлении), сам список неймспейсов и вся
    остальная логика не менялись ни на строчку. !!!Нужно проверить, так ли это!!!

    КРАТКАЯ ИНСТРУКЦИЯ ПО НАСТРОЙКЕ ПОД СВОЙ ЛИСТ:

    1) Замените картинку листа персонажа
       - ПКМ по объекту листа -> Custom -> вставьте свою ссылку на изображение
       - Нажмите Import и убедитесь, что лист загрузился
       - Сохраните партию (Save & Load -> Save Game)
       - Загрузите партию из только что созданного сейва

    2) Настройте таблицу defaultButtonData под расположение элементов
       на своей картинке (checkbox / counter / textbox / display / roll).
       Каждый элемент задаётся координатами pos = {x, y, z}, где:
         {0,0,0}   - центр листа
         {1,0,0}   - право,  {-1,0,0} - лево
         {0,0,-1}  - верх,   {0,0,1}  - низ
         0.1 по Y  - высота элемента над поверхностью листа (0 = внутри модели)
       Для подбора координат удобно использовать вспомогательный инструмент
       позиционирования TTS (панель Notes внизу справа).

    3) После правок нажмите Save & Apply в окне скрипта.
       Когда закончите настройку, установите disableSave = false ниже
       и снова Save & Apply — это включит сохранение состояния листа.
]]

-- true во время редактирования шаблона, false — когда лист готов к игре
-- (пока true, состояние листа НЕ сохраняется между сессиями)
disableSave = true

-- Цвет текста на кнопках (r, g, b от 0 до 1)
buttonFontColor = {0,0,0}
-- Цвет фона кнопок
buttonColor = {1,1,1}
-- Масштаб кнопок (менять не рекомендуется)
buttonScale = {0.1,0.1,0.1}

-- Символы для отображения состояния чекбокса (галочка / пусто)
CHECKBOX_CHAR_FULL = string.char(10008)
CHECKBOX_CHAR_EMPTY = ''
-- Компетентность (двойной бонус мастерства) — ПКМ по уже отмеченному чекбоксу
-- навыка (не спасброска). Отдельный символ, чтобы визуально отличаться от
-- обычной отметки мастерства.
CHECKBOX_CHAR_EXPERTISE = string.char(9733)

-- Таблица уровней по опыту (D&D 5e): диапазон опыта -> уровень и бонус мастерства
LVL_BY_EXP = {
    {
  min = 0,
  max = 299,
  lvl = 1,
  proficiency = 2,
    },
    {
  min = 300,
  max = 899,
  lvl = 2,
  proficiency = 2,
    },
    {
  min = 900,
  max = 2699,
  lvl = 3,
  proficiency = 2,
    },
    {
  min = 2700,
  max = 6499,
  lvl = 4,
  proficiency = 2,
    },
    {
  min = 6500,
  max = 13999,
  lvl = 5,
  proficiency = 3,
    },
    {
  min = 14000,
  max = 22999,
  lvl = 6,
  proficiency = 3,
    },
    {
  min = 23000,
  max = 33999,
  lvl = 7,
  proficiency = 3,
    },
    {
  min = 34000,
  max = 47999,
  lvl = 8,
  proficiency = 3,
    },
    {
  min = 48000,
  max = 63999,
  lvl = 9,
  proficiency = 4,
    },
    {
  min = 64000,
  max = 84999,
  lvl = 10,
  proficiency = 4,
    },
    {
  min = 85000,
  max = 99999,
  lvl = 11,
  proficiency = 4,
    },
    {
  min = 100000,
  max = 119999,
  lvl = 12,
  proficiency = 4,
    },
    {
  min = 120000,
  max = 139999,
  lvl = 13,
  proficiency = 5,
    },
    {
  min = 140000,
  max = 164999,
  lvl = 14,
  proficiency = 5,
    },
    {
  min = 165000,
  max = 194999,
  lvl = 15,
  proficiency = 5,
    },
    {
  min = 195000,
  max = 224999,
  lvl = 16,
  proficiency = 5,
    },
    {
  min = 225000,
  max = 264999,
  lvl = 17,
  proficiency = 6,
    },
    {
  min = 265000,
  max = 304999,
  lvl = 18,
  proficiency = 6,
    },
    {
  min = 305000,
  max = 354999,
  lvl = 19,
  proficiency = 6,
    },
    {
  min = 355000,
  max = 355000,
  lvl = 20,
  proficiency = 6,
    },
}

-- Минимальное и максимальное значение опыта из таблицы уровней
EXP_MIN = LVL_BY_EXP[1].min
EXP_MAX = LVL_BY_EXP[#LVL_BY_EXP].max

-- [ИСПРАВЛЕНО] Эти 4 константы были случайно потеряны при переводе
-- локальных *_ID переменных в глобальные (см. пояснение в шапке файла) —
-- из-за этого все текстовые поля бонусов навыков создавались с
-- font_size=nil/width=nil, а вес монет всегда показывал "Нет монет".
-- Восстановлены как глобальные, чтобы не увеличивать снова счётчик
-- локальных переменных чанка.

-- Размеры полей ввода бонусов навыков
TEXTBOX_SKILL_width = 280
TEXTBOX_SKILL_fontSize = 220
-- Коэффициент перевода фунтов в килограммы (для веса монет)
POUND_PER_KG = 0.454

NET_MONET_TEXT = 'Нет монет    ' -- текст с отступом для выравнивания

--================== Идентификаторы навыков ==================
SKILL_ACROBATICS_ID = "Acrobatics"
SKILL_ANIMAL_HANDLING_ID = "Animal_Handling"
SKILL_ARCANA_ID = "Arcana"
SKILL_ATHLETICS_ID = "Athletics"
SKILL_CHA_SAVETHROW_ID = "CHA_savethrow"
SKILL_CON_SAVETHROW_ID = "CON_savethrow"
SKILL_DECEPTION_ID = "Deception"
SKILL_DEX_SAVETHROW_ID = "DEX_savethrow"
SKILL_HISTORY_ID = "History"
SKILL_INSIGHT_ID = "Insight"
SKILL_INT_SAVETHROW_ID = "INT_savethrow"
SKILL_INTIMIDATION_ID = "Intimidation"
SKILL_INVESTIGATION_ID = "Investigation"
SKILL_MEDICINE_ID = "Medicine"
SKILL_NATURE_ID = "Nature"
SKILL_PERCEPTION_ID = "Perception"
SKILL_PERFORMANCE_ID = "Performance"
SKILL_PERSUASION_ID = "Persuasion"
SKILL_RELIGION_ID = "Religion"
SKILL_SLEIGHT_OF_HAND_ID = "Sleight_of_hand"
SKILL_STEALTH_ID = "Stealth"
SKILL_STR_SAVETHROW_ID = "STR_savethrow"
SKILL_SURVIVAL_ID = "Survival"
SKILL_WIS_SAVETHROW_ID = "WIS_savethrow"

--================== Идентификаторы характеристик ==================
PARAM_CHA_ID = "CHA"
PARAM_CON_ID = "CON"
PARAM_DEX_ID = "DEX"
PARAM_INT_ID = "INT"
PARAM_STR_ID = "STR"
PARAM_WIS_ID = "WIS"

-- Список всех навыков (используется, где нужно перебрать все навыки целиком)
local skillIdList = {
    SKILL_ACROBATICS_ID,
    SKILL_ANIMAL_HANDLING_ID,
    SKILL_ARCANA_ID,
    SKILL_ATHLETICS_ID,
    SKILL_CHA_SAVETHROW_ID,
    SKILL_CON_SAVETHROW_ID,
    SKILL_DECEPTION_ID,
    SKILL_DEX_SAVETHROW_ID,
    SKILL_HISTORY_ID,
    SKILL_INSIGHT_ID,
    SKILL_INT_SAVETHROW_ID,
    SKILL_INTIMIDATION_ID,
    SKILL_INVESTIGATION_ID,
    SKILL_MEDICINE_ID,
    SKILL_NATURE_ID,
    SKILL_PERCEPTION_ID,
    SKILL_PERFORMANCE_ID,
    SKILL_PERSUASION_ID,
    SKILL_RELIGION_ID,
    SKILL_SLEIGHT_OF_HAND_ID,
    SKILL_STEALTH_ID,
    SKILL_STR_SAVETHROW_ID,
    SKILL_SURVIVAL_ID,
    SKILL_WIS_SAVETHROW_ID,
}

-- Список всех характеристик
local paramIdList = {
    PARAM_CHA_ID,
    PARAM_CON_ID,
    PARAM_DEX_ID,
    PARAM_INT_ID,
    PARAM_STR_ID,
    PARAM_WIS_ID,
}

-- Какие навыки относятся к какой характеристике (характеристика -> список навыков)
local skillIdListByParamId = {
    [PARAM_CHA_ID] = {
  SKILL_CHA_SAVETHROW_ID,
  SKILL_DECEPTION_ID,
  SKILL_PERFORMANCE_ID,
  SKILL_PERSUASION_ID,
  SKILL_INTIMIDATION_ID,
    },
    [PARAM_CON_ID] = {
  SKILL_CON_SAVETHROW_ID,
    },
    [PARAM_DEX_ID] = {
  SKILL_DEX_SAVETHROW_ID,
  SKILL_ACROBATICS_ID,
  SKILL_SLEIGHT_OF_HAND_ID,
  SKILL_STEALTH_ID,
    },
    [PARAM_INT_ID] = {
  SKILL_INT_SAVETHROW_ID,
  SKILL_ARCANA_ID,
  SKILL_HISTORY_ID,
  SKILL_INVESTIGATION_ID,
  SKILL_NATURE_ID,
  SKILL_RELIGION_ID,
    },
    [PARAM_STR_ID] = {
  SKILL_STR_SAVETHROW_ID,
  SKILL_ATHLETICS_ID,
    },
    [PARAM_WIS_ID] = {
  SKILL_WIS_SAVETHROW_ID,
  SKILL_ANIMAL_HANDLING_ID,
  SKILL_INSIGHT_ID,
  SKILL_MEDICINE_ID,
  SKILL_PERCEPTION_ID,
  SKILL_SURVIVAL_ID,
    },
}

-- Порядок и русские подписи характеристик для диалога выбора
-- заклинательной характеристики
local spellAbilityOptions = {PARAM_STR_ID, PARAM_DEX_ID, PARAM_CON_ID, PARAM_INT_ID, PARAM_WIS_ID, PARAM_CHA_ID}
local spellAbilityLabels = {
    [PARAM_STR_ID] = "СИЛ",
    [PARAM_DEX_ID] = "ЛОВ",
    [PARAM_CON_ID] = "ТЕЛ",
    [PARAM_INT_ID] = "ИНТ",
    [PARAM_WIS_ID] = "МУД",
    [PARAM_CHA_ID] = "ХАР",
}

-- Обратное соответствие: по навыку узнать его базовую характеристику
local paramIdBySkillId = {
    [SKILL_ACROBATICS_ID] = PARAM_DEX_ID,
    [SKILL_ANIMAL_HANDLING_ID] = PARAM_WIS_ID,
    [SKILL_ARCANA_ID] = PARAM_INT_ID,
    [SKILL_ATHLETICS_ID] = PARAM_STR_ID,
    [SKILL_CHA_SAVETHROW_ID] = PARAM_CHA_ID,
    [SKILL_CON_SAVETHROW_ID] = PARAM_CON_ID,
    [SKILL_DECEPTION_ID] = PARAM_CHA_ID,
    [SKILL_DEX_SAVETHROW_ID] = PARAM_DEX_ID,
    [SKILL_HISTORY_ID] = PARAM_INT_ID,
    [SKILL_INSIGHT_ID] = PARAM_WIS_ID,
    [SKILL_INT_SAVETHROW_ID] = PARAM_INT_ID,
    [SKILL_INTIMIDATION_ID] = PARAM_CHA_ID,
    [SKILL_INVESTIGATION_ID] = PARAM_INT_ID,
    [SKILL_MEDICINE_ID] = PARAM_WIS_ID,
    [SKILL_NATURE_ID] = PARAM_INT_ID,
    [SKILL_PERCEPTION_ID] = PARAM_WIS_ID,
    [SKILL_PERFORMANCE_ID] = PARAM_CHA_ID,
    [SKILL_PERSUASION_ID] = PARAM_CHA_ID,
    [SKILL_RELIGION_ID] = PARAM_INT_ID,
    [SKILL_SLEIGHT_OF_HAND_ID] = PARAM_DEX_ID,
    [SKILL_STEALTH_ID] = PARAM_DEX_ID,
    [SKILL_STR_SAVETHROW_ID] = PARAM_STR_ID,
    [SKILL_SURVIVAL_ID] = PARAM_WIS_ID,
    [SKILL_WIS_SAVETHROW_ID] = PARAM_WIS_ID,
}

-- Спасброски компетентность не поддерживают — только обычные проверки навыков
function isSkillSavethrow(skillId)
    if skillId == nil then return false end
    return skillId:find("_savethrow") ~= nil
end

-- Множитель бонуса мастерства для чекбокса навыка:
-- 0 — не отмечен, 1 — отмечен (обычное мастерство),
-- 2 — Компетентность (двойной бонус мастерства)
function getProficiencyMultiplier(checkbox)
    if checkbox.state ~= true then
        return 0
    end
    if checkbox.expertise == true then
        return 2
    end
    return 1
end

--================== Идентификаторы текстовых полей ==================
TEXTBOX_NAME_ID = "textbox_Name"
TEXTBOX_CLASS_LEVEL_ID = "textbox_Class_Level"
TEXTBOX_BACKGROUND_ID = "textbox_Background"
TEXTBOX_PLAYERS_NAME_ID = "textbox_Players_name"
TEXTBOX_RACE_ID = "textbox_Race"
TEXTBOX_ALIGMENT_ID = "textbox_Aligment"
TEXTBOX_XP_ID = "textbox_XP"
TEXTBOX_AGE_ID = "textbox_Age"
TEXTBOX_AC_ID = "textbox_AC"
RESOURCE_COUNTER_HP_MAX_ID = "resourceCounter_HP_max"
RESOURCE_COUNTER_HP_TEMPORARY_ID = "resourceCounter_HP_temporary"
TEXTBOX_HIT_DICES_ID = "textbox_Hit_Dices"
TEXTBOX_INITIATIVE_ID = "textbox_Initiative"
TEXTBOX_SPEED_ID = "textbox_Speed"
TEXTBOX_VISION_ID = "textbox_Vision"
RESOURCE_COUNTER_HP_CURRENT_ID = "resourceCounter_HP_current"
TEXTBOX_WEAPON_NAME_1_ID = "textbox_Weapon_Name_1"
TEXTBOX_WEAPON_NAME_2_ID = "textbox_Weapon_Name_2"
TEXTBOX_WEAPON_NAME_3_ID = "textbox_Weapon_Name_3"
TEXTBOX_WEAPON_NAME_4_ID = "textbox_Weapon_Name_4"
TEXTBOX_WEAPON_NAME_5_ID = "textbox_Weapon_Name_5"
TEXTBOX_WEAPON_NAME_6_ID = "textbox_Weapon_Name_6"
TEXTBOX_WEAPON_NAME_7_ID = "textbox_Weapon_Name_7"
TEXTBOX_HIT_1_ID = "textbox_Hit_1"
TEXTBOX_HIT_2_ID = "textbox_Hit_2"
TEXTBOX_HIT_3_ID = "textbox_Hit_3"
TEXTBOX_HIT_4_ID = "textbox_Hit_4"
TEXTBOX_HIT_5_ID = "textbox_Hit_5"
TEXTBOX_HIT_6_ID = "textbox_Hit_6"
TEXTBOX_HIT_7_ID = "textbox_Hit_7"
TEXTBOX_DAMAGE_DICE_COUNT_1_ID = "textbox_Damage_Dice_Count_Type_1"
TEXTBOX_DAMAGE_DICE_COUNT_2_ID = "textbox_Damage_Dice_Count_Type_2"
TEXTBOX_DAMAGE_DICE_COUNT_3_ID = "textbox_Damage_Dice_Count_Type_3"
TEXTBOX_DAMAGE_DICE_COUNT_4_ID = "textbox_Damage_Dice_Count_Type_4"
TEXTBOX_DAMAGE_DICE_COUNT_5_ID = "textbox_Damage_Dice_Count_Type_5"
TEXTBOX_DAMAGE_DICE_COUNT_6_ID = "textbox_Damage_Dice_Count_Type_6"
TEXTBOX_DAMAGE_DICE_COUNT_7_ID = "textbox_Damage_Dice_Count_Type_7"
TEXTBOX_DAMAGE_DICE_TYPE_1_ID = "textbox_Damage_Dice_Type_1"
TEXTBOX_DAMAGE_DICE_TYPE_2_ID = "textbox_Damage_Dice_Type_2"
TEXTBOX_DAMAGE_DICE_TYPE_3_ID = "textbox_Damage_Dice_Type_3"
TEXTBOX_DAMAGE_DICE_TYPE_4_ID = "textbox_Damage_Dice_Type_4"
TEXTBOX_DAMAGE_DICE_TYPE_5_ID = "textbox_Damage_Dice_Type_5"
TEXTBOX_DAMAGE_DICE_TYPE_6_ID = "textbox_Damage_Dice_Type_6"
TEXTBOX_DAMAGE_DICE_TYPE_7_ID = "textbox_Damage_Dice_Type_7"
TEXTBOX_DAMAGE_BONUS_1_ID = "textbox_Damage_Bonus_1"
TEXTBOX_DAMAGE_BONUS_2_ID = "textbox_Damage_Bonus_2"
TEXTBOX_DAMAGE_BONUS_3_ID = "textbox_Damage_Bonus_3"
TEXTBOX_DAMAGE_BONUS_4_ID = "textbox_Damage_Bonus_4"
TEXTBOX_DAMAGE_BONUS_5_ID = "textbox_Damage_Bonus_5"
TEXTBOX_DAMAGE_BONUS_6_ID = "textbox_Damage_Bonus_6"
TEXTBOX_DAMAGE_BONUS_7_ID = "textbox_Damage_Bonus_7"
TEXTBOX_NOTES_1_ID = "textbox_Notes_1"
TEXTBOX_NOTES_2_ID = "textbox_Notes_2"
TEXTBOX_NOTES_3_ID = "textbox_Notes_3"
TEXTBOX_NOTES_4_ID = "textbox_Notes_4"
TEXTBOX_NOTES_5_ID = "textbox_Notes_5"
TEXTBOX_NOTES_6_ID = "textbox_Notes_6"
TEXTBOX_NOTES_7_ID = "textbox_Notes_7"
RESOURCE_COUNTER_COPPER_COINS_ID = "resourceCounter_Copper_coins"
RESOURCE_COUNTER_SILVER_COINS_ID = "resourceCounter_Silver_coins"
RESOURCE_COUNTER_ELECTRUM_COINS_ID = "resourceCounter_Electrum_coins"
RESOURCE_COUNTER_GOLD_COINS_ID = "resourceCounter_Gold_coins"
RESOURCE_COUNTER_PLATINUM_COINS_ID = "resourceCounter_Platinum_coins"
TEXTBOX_EQUIPMENT_ID = "textbox_Equipment"                     -- Снаряжение (текст)
TEXTBOX_SPELL_CLASS_ID = "textbox_Spell_Class"                 -- 1. Класс заклинателя (текст)
SELECT_SPELLCASTING_ABILITY_ID = "select_Spellcasting_Ability" -- 2. Заклинательная характеристика (выбор диалогом)
TEXTBOX_SPELL_SAVE_DC_ID = "textbox_Spell_Save_DC"              -- 3. Сложность спасброска (x+y+z)
TEXTBOX_SPELL_ATTACK_BONUS_ID = "textbox_Spell_Attack_Bonus"    -- 4. Бонус атаки заклинанием (x+y+z)
TEXTBOX_HEIGHT_ID = "textbox_Height"
TEXTBOX_CLASS_RACE_CHARACTERISTICS_ID = "textbox_Class_Race_Characteristics"
TEXTBOX_WEIGHT_ID = "textbox_Weight"
TEXTBOX_PROFICIENCY_OTHER_ID = "textbox_Proficiency_other"
TEXTBOX_SKILL_STR_SAVETHROW_ID = "textbox_"..SKILL_STR_SAVETHROW_ID
TEXTBOX_SKILL_ATHLETICS_ID = "textbox_"..SKILL_ATHLETICS_ID
TEXTBOX_SKILL_DEX_SAVETHROW_ID = "textbox_"..SKILL_DEX_SAVETHROW_ID
TEXTBOX_SKILL_ACROBATICS_ID = "textbox_"..SKILL_ACROBATICS_ID
TEXTBOX_SKILL_STEALTH_ID = "textbox_"..SKILL_STEALTH_ID
TEXTBOX_SKILL_SLEIGHT_OF_HAND_ID = "textbox_"..SKILL_SLEIGHT_OF_HAND_ID
TEXTBOX_SKILL_CON_SAVETHROW_ID = "textbox_"..SKILL_CON_SAVETHROW_ID
TEXTBOX_SKILL_INT_SAVETHROW_ID = "textbox_"..SKILL_INT_SAVETHROW_ID
TEXTBOX_SKILL_ARCANA_ID = "textbox_"..SKILL_ARCANA_ID
TEXTBOX_SKILL_HISTORY_ID = "textbox_"..SKILL_HISTORY_ID
TEXTBOX_SKILL_INVESTIGATION_ID = "textbox_"..SKILL_INVESTIGATION_ID
TEXTBOX_SKILL_NATURE_ID = "textbox_"..SKILL_NATURE_ID
TEXTBOX_SKILL_RELIGION_ID = "textbox_"..SKILL_RELIGION_ID
TEXTBOX_SKILL_WIS_SAVETHROW_ID = "textbox_"..SKILL_WIS_SAVETHROW_ID
TEXTBOX_SKILL_ANIMAL_HANDLING_ID = "textbox_"..SKILL_ANIMAL_HANDLING_ID
TEXTBOX_SKILL_INSIGHT_ID = "textbox_"..SKILL_INSIGHT_ID
TEXTBOX_SKILL_MEDICINE_ID = "textbox_"..SKILL_MEDICINE_ID
TEXTBOX_SKILL_PERCEPTION_ID = "textbox_"..SKILL_PERCEPTION_ID
TEXTBOX_SKILL_SURVIVAL_ID = "textbox_"..SKILL_SURVIVAL_ID
TEXTBOX_SKILL_CHA_SAVETHROW_ID = "textbox_"..SKILL_CHA_SAVETHROW_ID
TEXTBOX_SKILL_PERFORMANCE_ID = "textbox_"..SKILL_PERFORMANCE_ID
TEXTBOX_SKILL_DECEPTION_ID = "textbox_"..SKILL_DECEPTION_ID
TEXTBOX_SKILL_INTIMIDATION_ID = "textbox_"..SKILL_INTIMIDATION_ID
TEXTBOX_SKILL_PERSUASION_ID = "textbox_"..SKILL_PERSUASION_ID

--================== Идентификаторы чекбоксов ==================
CHECKBOX_SKILL_STR_SAVETHROW_ID = "checkbox_"..SKILL_STR_SAVETHROW_ID
CHECKBOX_SKILL_ATHLETICS_ID = "checkbox_"..SKILL_ATHLETICS_ID
CHECKBOX_SKILL_DEX_SAVETHROW_ID = "checkbox_"..SKILL_DEX_SAVETHROW_ID
CHECKBOX_SKILL_ACROBATICS_ID = "checkbox_"..SKILL_ACROBATICS_ID
CHECKBOX_SKILL_STEALTH_ID = "checkbox_"..SKILL_STEALTH_ID
CHECKBOX_SKILL_SLEIGHT_OF_HAND_ID = "checkbox_"..SKILL_SLEIGHT_OF_HAND_ID
CHECKBOX_SKILL_CON_SAVETHROW_ID = "checkbox_"..SKILL_CON_SAVETHROW_ID
CHECKBOX_SKILL_INT_SAVETHROW_ID = "checkbox_"..SKILL_INT_SAVETHROW_ID
CHECKBOX_SKILL_ARCANA_ID = "checkbox_"..SKILL_ARCANA_ID
CHECKBOX_SKILL_HISTORY_ID = "checkbox_"..SKILL_HISTORY_ID
CHECKBOX_SKILL_INVESTIGATION_ID = "checkbox_"..SKILL_INVESTIGATION_ID
CHECKBOX_SKILL_NATURE_ID = "checkbox_"..SKILL_NATURE_ID
CHECKBOX_SKILL_RELIGION_ID = "checkbox_"..SKILL_RELIGION_ID
CHECKBOX_SKILL_WIS_SAVETHROW_ID = "checkbox_"..SKILL_WIS_SAVETHROW_ID
CHECKBOX_SKILL_ANIMAL_HANDLING_ID = "checkbox_"..SKILL_ANIMAL_HANDLING_ID
CHECKBOX_SKILL_INSIGHT_ID = "checkbox_"..SKILL_INSIGHT_ID
CHECKBOX_SKILL_MEDICINE_ID = "checkbox_"..SKILL_MEDICINE_ID
CHECKBOX_SKILL_PERCEPTION_ID = "checkbox_"..SKILL_PERCEPTION_ID
CHECKBOX_SKILL_SURVIVAL_ID = "checkbox_"..SKILL_SURVIVAL_ID
CHECKBOX_SKILL_CHA_SAVETHROW_ID = "checkbox_"..SKILL_CHA_SAVETHROW_ID
CHECKBOX_SKILL_PERFORMANCE_ID = "checkbox_"..SKILL_PERFORMANCE_ID
CHECKBOX_SKILL_DECEPTION_ID = "checkbox_"..SKILL_DECEPTION_ID
CHECKBOX_SKILL_INTIMIDATION_ID = "checkbox_"..SKILL_INTIMIDATION_ID
CHECKBOX_SKILL_PERSUASION_ID = "checkbox_"..SKILL_PERSUASION_ID
CHECKBOX_LIGHT_ARMOR_ID = "checkbox_Light_Armor"
CHECKBOX_MEDIUM_ARMOR_ID = "checkbox_Medium_Armor"
CHECKBOX_HEAVY_ARMOR_ID = "checkbox_Heavy_Armor"
CHECKBOX_SHIELD_ID = "checkbox_Shield"
CHECKBOX_SIMPLE_WEAPONS_ID = "checkbox_Simple_Weapons"
CHECKBOX_MARTIAL_WEAPONS_ID = "checkbox_Martial_Weapons"
CHECKBOX_DEATH_SAVETHROW_SUCCESS_1_ID = "checkbox_Death_savethrow_success_1"
CHECKBOX_DEATH_SAVETHROW_SUCCESS_2_ID = "checkbox_Death_savethrow_success_2"
CHECKBOX_DEATH_SAVETHROW_SUCCESS_3_ID = "checkbox_Death_savethrow_success_3"
CHECKBOX_DEATH_SAVETHROW_FAIL_1_ID = "checkbox_Death_savethrow_fail_1"
CHECKBOX_DEATH_SAVETHROW_FAIL_2_ID = "checkbox_Death_savethrow_fail_2"
CHECKBOX_DEATH_SAVETHROW_FAIL_3_ID = "checkbox_Death_savethrow_fail_3"
local CHECKBOX_WEIGHT_CAPACITY_X_2 = "checkbox_WEIGHT_CAPACITY_X_2"

--================== Идентификаторы счётчиков характеристик ==================
COUNTER_PARAM_STR_ID = "counter_"..PARAM_STR_ID
COUNTER_PARAM_DEX_ID = "counter_"..PARAM_DEX_ID
COUNTER_PARAM_CON_ID = "counter_"..PARAM_CON_ID
COUNTER_PARAM_INT_ID = "counter_"..PARAM_INT_ID
COUNTER_PARAM_WIS_ID = "counter_"..PARAM_WIS_ID
COUNTER_PARAM_CHA_ID = "counter_"..PARAM_CHA_ID

--================== Идентификаторы дисплеев (нередактируемые значения) ==================
DISPLAY_PARAM_STR_ID = "display_"..PARAM_STR_ID
DISPLAY_PARAM_DEX_ID = "display_"..PARAM_DEX_ID
DISPLAY_PARAM_CON_ID = "display_"..PARAM_CON_ID
DISPLAY_PARAM_INT_ID = "display_"..PARAM_INT_ID
DISPLAY_PARAM_WIS_ID = "display_"..PARAM_WIS_ID
DISPLAY_PARAM_CHA_ID = "display_"..PARAM_CHA_ID
DISPLAY_SKILL_STR_SAVETHROW_ID = "display_"..SKILL_STR_SAVETHROW_ID
DISPLAY_SKILL_ATHLETICS_ID = "display_"..SKILL_ATHLETICS_ID
DISPLAY_SKILL_DEX_SAVETHROW_ID = "display_"..SKILL_DEX_SAVETHROW_ID
DISPLAY_SKILL_ACROBATICS_ID = "display_"..SKILL_ACROBATICS_ID
DISPLAY_SKILL_STEALTH_ID = "display_"..SKILL_STEALTH_ID
DISPLAY_SKILL_SLEIGHT_OF_HAND_ID = "display_"..SKILL_SLEIGHT_OF_HAND_ID
DISPLAY_SKILL_CON_SAVETHROW_ID = "display_"..SKILL_CON_SAVETHROW_ID
DISPLAY_SKILL_INT_SAVETHROW_ID = "display_"..SKILL_INT_SAVETHROW_ID
DISPLAY_SKILL_ARCANA_ID = "display_"..SKILL_ARCANA_ID
DISPLAY_SKILL_HISTORY_ID = "display_"..SKILL_HISTORY_ID
DISPLAY_SKILL_INVESTIGATION_ID = "display_"..SKILL_INVESTIGATION_ID
DISPLAY_SKILL_NATURE_ID = "display_"..SKILL_NATURE_ID
DISPLAY_SKILL_RELIGION_ID = "display_"..SKILL_RELIGION_ID
DISPLAY_SKILL_WIS_SAVETHROW_ID = "display_"..SKILL_WIS_SAVETHROW_ID
DISPLAY_SKILL_ANIMAL_HANDLING_ID = "display_"..SKILL_ANIMAL_HANDLING_ID
DISPLAY_SKILL_INSIGHT_ID = "display_"..SKILL_INSIGHT_ID
DISPLAY_SKILL_MEDICINE_ID = "display_"..SKILL_MEDICINE_ID
DISPLAY_SKILL_PERCEPTION_ID = "display_"..SKILL_PERCEPTION_ID
DISPLAY_SKILL_SURVIVAL_ID = "display_"..SKILL_SURVIVAL_ID
DISPLAY_SKILL_CHA_SAVETHROW_ID = "display_"..SKILL_CHA_SAVETHROW_ID
DISPLAY_SKILL_PERFORMANCE_ID = "display_"..SKILL_PERFORMANCE_ID
DISPLAY_SKILL_DECEPTION_ID = "display_"..SKILL_DECEPTION_ID
DISPLAY_SKILL_INTIMIDATION_ID = "display_"..SKILL_INTIMIDATION_ID
DISPLAY_SKILL_PERSUASION_ID = "display_"..SKILL_PERSUASION_ID
DISPLAY_PASSIVE_PERCEPTION_ID = "display_Passive_Perception"
DISPLAY_WEIGHT_CAPACITY_ID = "display_Weight_Capacity"
DISPLAY_RAISE_LIFT_AND_PULL_ID = "display_Raise_Lift_and_Pull"
DISPLAY_JUMP_HEIGHT_ID = "display_Jump_Height"
DISPLAY_JUMP_DISTANCE_ID = "display_Jump_Distance"
DISPLAY_JUMP_HEIGHT_WITH_HANDS_ID = "display_Jump_Height_with_Hands"
DISPLAY_JUMP_HEIGHT_NO_RUNNING_ID = "display_Jump_Height_no_running"
DISPLAY_JUMP_DISTANCE_NO_RUNNING_ID = "display_Jump_Distance_no_running"
DISPLAY_JUMP_HEIGHT_WITH_HANDS_NO_RUNNING_ID = "display_Jump_Height_with_Hands_no_running"
DISPLAY_LEVEL_ID = "display_Level"
DISPLAY_NEXT_LVL_ID = "display_next_LVL"
DISPLAY_PROFICIENCY_ID = "display_Proficiency"
DISPLAY_HIT_DICES_LEFT_ID = "display_Hit_Dices_Left"
DISPLAY_MONET_WEIGHT_ID = "display_MONET_WEIGHT_Left"

--================== Идентификаторы кнопок бросков костей ==================
ROLL_PARAM_STR_ID = "roll_param_str"
ROLL_PARAM_DEX_ID = "roll_param_dex"
ROLL_PARAM_CON_ID = "roll_param_con"
ROLL_PARAM_INT_ID = "roll_param_int"
ROLL_PARAM_WIS_ID = "roll_param_WIS"
ROLL_PARAM_CHA_ID = "roll_param_cha"
ROLL_SKILL_STR_SAVETHROW_ID = "roll_skill_str_savethrow"
ROLL_SKILL_ATHLETICS_ID = "roll_skill_athletics"
ROLL_SKILL_DEX_SAVETHROW_ID = "roll_skill_dex_savethrow"
ROLL_SKILL_ACROBATICS_ID = "roll_skill_acrobatics"
ROLL_SKILL_STEALTH_ID = "roll_skill_stealth"
ROLL_SKILL_SLEIGHT_OF_HAND_ID = "roll_skill_sleight_of_hand"
ROLL_SKILL_CON_SAVETHROW_ID = "roll_skill_con_savethrow"
ROLL_SKILL_INT_SAVETHROW_ID = "roll_skill_int_savethrow"
ROLL_SKILL_ARCANA_ID = "roll_skill_arcana"
ROLL_SKILL_HISTORY_ID = "roll_skill_history"
ROLL_SKILL_INVESTIGATION_ID = "roll_skill_investigation"
ROLL_SKILL_NATURE_ID = "roll_skill_nature"
ROLL_SKILL_RELIGION_ID = "roll_skill_religion"
ROLL_SKILL_WIS_SAVETHROW_ID = "roll_skill_wis_savethrow"
ROLL_SKILL_ANIMAL_HANDLING_ID = "roll_skill_animal_handling"
ROLL_SKILL_INSIGHT_ID = "roll_skill_insight"
ROLL_SKILL_MEDICINE_ID = "roll_skill_medicine"
ROLL_SKILL_PERCEPTION_ID = "roll_skill_perception"
ROLL_SKILL_SURVIVAL_ID = "roll_skill_survival"
ROLL_SKILL_CHA_SAVETHROW_ID = "roll_skill_cha_savethrow"
ROLL_SKILL_PERFORMANCE_ID = "roll_skill_performance"
ROLL_SKILL_DECEPTION_ID = "roll_skill_deception"
ROLL_SKILL_INTIMIDATION_ID = "roll_skill_intimidation"
ROLL_SKILL_PERSUASION_ID = "roll_skill_persuasion"

-- Подписи на кнопках бросков (короткое название характеристики/навыка)
local rollLabelCollection = {
    [ROLL_PARAM_STR_ID] = "Сила",
    [ROLL_PARAM_DEX_ID] = "Ловкость",
    [ROLL_PARAM_CON_ID] = "Телосложение",
    [ROLL_PARAM_INT_ID] = "Интеллект",
    [ROLL_PARAM_WIS_ID] = "Мудрость",
    [ROLL_PARAM_CHA_ID] = "Харизма",
    [ROLL_SKILL_STR_SAVETHROW_ID] = "Испытание",
    [ROLL_SKILL_ATHLETICS_ID] = "Атлетика",
    [ROLL_SKILL_DEX_SAVETHROW_ID] = "Испытание",
    [ROLL_SKILL_ACROBATICS_ID] = "Акробатика",
    [ROLL_SKILL_STEALTH_ID] = "Скрытность",
    [ROLL_SKILL_SLEIGHT_OF_HAND_ID] = "Ловкость рук",
    [ROLL_SKILL_CON_SAVETHROW_ID] = "Испытание",
    [ROLL_SKILL_INT_SAVETHROW_ID] = "Испытание",
    [ROLL_SKILL_ARCANA_ID] = "Магия",
    [ROLL_SKILL_HISTORY_ID] = "История",
    [ROLL_SKILL_INVESTIGATION_ID] = "Анализ",
    [ROLL_SKILL_NATURE_ID] = "Природа",
    [ROLL_SKILL_RELIGION_ID] = "Религия",
    [ROLL_SKILL_WIS_SAVETHROW_ID] = "Испытание",
    [ROLL_SKILL_ANIMAL_HANDLING_ID] = "Обращение с животными",
    [ROLL_SKILL_INSIGHT_ID] = "Проницательность",
    [ROLL_SKILL_MEDICINE_ID] = "Медицина",
    [ROLL_SKILL_PERCEPTION_ID] = "Внимательность",
    [ROLL_SKILL_SURVIVAL_ID] = "Выживание",
    [ROLL_SKILL_CHA_SAVETHROW_ID] = "Испытание",
    [ROLL_SKILL_PERFORMANCE_ID] = "Выступление",
    [ROLL_SKILL_DECEPTION_ID] = "Обман",
    [ROLL_SKILL_INTIMIDATION_ID] = "Запугивание",
    [ROLL_SKILL_PERSUASION_ID] = "Убеждение",
}

-- Текст, который выводится в чат при броске (что именно проверяется/испытывается)
local rollTextCollection = {
    [ROLL_PARAM_STR_ID] = "проверка [b]Силы[/b]",
    [ROLL_PARAM_DEX_ID] = "проверка [b]Ловкости[/b]",
    [ROLL_PARAM_CON_ID] = "проверка [b]Телосложения[/b]",
    [ROLL_PARAM_INT_ID] = "проверка [b]Интеллекта[/b]",
    [ROLL_PARAM_WIS_ID] = "проверка [b]Мудрости[/b]",
    [ROLL_PARAM_CHA_ID] = "проверка [b]Харизмы[/b]",
    [ROLL_SKILL_STR_SAVETHROW_ID] = "испытание [b]Силы[/b]",
    [ROLL_SKILL_ATHLETICS_ID] = "проверка [b]Атлетики[/b]",
    [ROLL_SKILL_DEX_SAVETHROW_ID] = "испытание [b]Ловкости[/b]",
    [ROLL_SKILL_ACROBATICS_ID] = "проверка [b]Акробатики[/b]",
    [ROLL_SKILL_STEALTH_ID] = "проверка [b]Скрытности[/b]",
    [ROLL_SKILL_SLEIGHT_OF_HAND_ID] = "проверка [b]Ловкости[/b] рук",
    [ROLL_SKILL_CON_SAVETHROW_ID] = "испытание [b]Телосложения[/b]",
    [ROLL_SKILL_INT_SAVETHROW_ID] = "испытание [b]Интеллекта[/b]",
    [ROLL_SKILL_ARCANA_ID] = "проверка [b]Магии[/b]",
    [ROLL_SKILL_HISTORY_ID] = "проверка [b]Истории[/b]",
    [ROLL_SKILL_INVESTIGATION_ID] = "проверка [b]Анализа[/b]",
    [ROLL_SKILL_NATURE_ID] = "проверка [b]Природы[/b]",
    [ROLL_SKILL_RELIGION_ID] = "проверка [b]Религии[/b]",
    [ROLL_SKILL_WIS_SAVETHROW_ID] = "испытание [b]Мудрости[/b]",
    [ROLL_SKILL_ANIMAL_HANDLING_ID] = "проверка [b]Обращения[/b] с животными",
    [ROLL_SKILL_INSIGHT_ID] = "проверка [b]Проницательности[/b]",
    [ROLL_SKILL_MEDICINE_ID] = "проверка [b]Медицины[/b]",
    [ROLL_SKILL_PERCEPTION_ID] = "проверка [b]Внимательности[/b]",
    [ROLL_SKILL_SURVIVAL_ID] = "проверка [b]Выживания[/b]",
    [ROLL_SKILL_CHA_SAVETHROW_ID] = "испытание [b]Харизмы[/b]",
    [ROLL_SKILL_PERFORMANCE_ID] = "проверка [b]Выступления[/b]",
    [ROLL_SKILL_DECEPTION_ID] = "проверка [b]Обмана[/b]",
    [ROLL_SKILL_INTIMIDATION_ID] = "проверка [b]Запугивания[/b]",
    [ROLL_SKILL_PERSUASION_ID] = "проверка [b]Убеждения[/b]",
}

-- Подписи (плейсхолдеры/labels) и значения по умолчанию для текстовых полей
local textboxLabelCollection = {
    [TEXTBOX_NAME_ID] = "Имя персонажа",
    [TEXTBOX_CLASS_LEVEL_ID] = "Класс",
    [TEXTBOX_BACKGROUND_ID] = "Предыстория",
    [TEXTBOX_PLAYERS_NAME_ID] = "Имя игрока",
    [TEXTBOX_RACE_ID] = "Раса",
    [TEXTBOX_ALIGMENT_ID] = "Мировоззрение",
    [TEXTBOX_XP_ID] = "Опыт",
    [TEXTBOX_AGE_ID] = "Возраст",
    [TEXTBOX_AC_ID] = "KД",
    [TEXTBOX_HIT_DICES_ID] = "",
    [TEXTBOX_INITIATIVE_ID] = "+0",
    [TEXTBOX_SPEED_ID] = "",
    [TEXTBOX_VISION_ID] = "обычное",
    [TEXTBOX_WEAPON_NAME_1_ID] = "Длинный меч",
    [TEXTBOX_WEAPON_NAME_2_ID] = "",
    [TEXTBOX_WEAPON_NAME_3_ID] = "",
    [TEXTBOX_WEAPON_NAME_4_ID] = "",
    [TEXTBOX_WEAPON_NAME_5_ID] = "",
    [TEXTBOX_WEAPON_NAME_6_ID] = "",
    [TEXTBOX_WEAPON_NAME_7_ID] = "",
    [TEXTBOX_HIT_1_ID] = "+0",
    [TEXTBOX_HIT_2_ID] = "",
    [TEXTBOX_HIT_3_ID] = "",
    [TEXTBOX_HIT_4_ID] = "",
    [TEXTBOX_HIT_5_ID] = "",
    [TEXTBOX_HIT_6_ID] = "",
    [TEXTBOX_HIT_7_ID] = "",
    [TEXTBOX_DAMAGE_DICE_COUNT_1_ID] = "1",
    [TEXTBOX_DAMAGE_DICE_COUNT_2_ID] = "",
    [TEXTBOX_DAMAGE_DICE_COUNT_3_ID] = "",
    [TEXTBOX_DAMAGE_DICE_COUNT_4_ID] = "",
    [TEXTBOX_DAMAGE_DICE_COUNT_5_ID] = "",
    [TEXTBOX_DAMAGE_DICE_COUNT_6_ID] = "",
    [TEXTBOX_DAMAGE_DICE_COUNT_7_ID] = "",
    [TEXTBOX_DAMAGE_DICE_TYPE_1_ID] = "8",
    [TEXTBOX_DAMAGE_DICE_TYPE_2_ID] = "",
    [TEXTBOX_DAMAGE_DICE_TYPE_3_ID] = "",
    [TEXTBOX_DAMAGE_DICE_TYPE_4_ID] = "",
    [TEXTBOX_DAMAGE_DICE_TYPE_5_ID] = "",
    [TEXTBOX_DAMAGE_DICE_TYPE_6_ID] = "",
    [TEXTBOX_DAMAGE_DICE_TYPE_7_ID] = "",
    [TEXTBOX_DAMAGE_BONUS_1_ID] = "+0",
    [TEXTBOX_DAMAGE_BONUS_2_ID] = "",
    [TEXTBOX_DAMAGE_BONUS_3_ID] = "",
    [TEXTBOX_DAMAGE_BONUS_4_ID] = "",
    [TEXTBOX_DAMAGE_BONUS_5_ID] = "",
    [TEXTBOX_DAMAGE_BONUS_6_ID] = "",
    [TEXTBOX_DAMAGE_BONUS_7_ID] = "",
    [TEXTBOX_NOTES_1_ID] = "рубящий",
    [TEXTBOX_NOTES_2_ID] = "",
    [TEXTBOX_NOTES_3_ID] = "",
    [TEXTBOX_NOTES_4_ID] = "",
    [TEXTBOX_NOTES_5_ID] = "",
    [TEXTBOX_NOTES_6_ID] = "",
    [TEXTBOX_NOTES_7_ID] = "",
    [TEXTBOX_EQUIPMENT_ID] = "",
    [TEXTBOX_SPELL_CLASS_ID] = "",
    [TEXTBOX_SPELL_SAVE_DC_ID] = "",
    [TEXTBOX_SPELL_ATTACK_BONUS_ID] = "",
    [TEXTBOX_CLASS_RACE_CHARACTERISTICS_ID] = "",
    [TEXTBOX_HEIGHT_ID] = "Рост",
    [TEXTBOX_WEIGHT_ID] = "Вес",
    [TEXTBOX_PROFICIENCY_OTHER_ID] = "",
    [TEXTBOX_SKILL_STR_SAVETHROW_ID] = "0",
    [TEXTBOX_SKILL_ATHLETICS_ID] = "0",
    [TEXTBOX_SKILL_DEX_SAVETHROW_ID] = "0",
    [TEXTBOX_SKILL_ACROBATICS_ID] = "0",
    [TEXTBOX_SKILL_STEALTH_ID] = "0",
    [TEXTBOX_SKILL_SLEIGHT_OF_HAND_ID] = "0",
    [TEXTBOX_SKILL_CON_SAVETHROW_ID] = "0",
    [TEXTBOX_SKILL_INT_SAVETHROW_ID] = "0",
    [TEXTBOX_SKILL_ARCANA_ID] = "0",
    [TEXTBOX_SKILL_HISTORY_ID] = "0",
    [TEXTBOX_SKILL_INVESTIGATION_ID] = "0",
    [TEXTBOX_SKILL_NATURE_ID] = "0",
    [TEXTBOX_SKILL_RELIGION_ID] = "0",
    [TEXTBOX_SKILL_WIS_SAVETHROW_ID] = "0",
    [TEXTBOX_SKILL_ANIMAL_HANDLING_ID] = "0",
    [TEXTBOX_SKILL_INSIGHT_ID] = "0",
    [TEXTBOX_SKILL_MEDICINE_ID] = "0",
    [TEXTBOX_SKILL_PERCEPTION_ID] = "0",
    [TEXTBOX_SKILL_SURVIVAL_ID] = "0",
    [TEXTBOX_SKILL_CHA_SAVETHROW_ID] = "0",
    [TEXTBOX_SKILL_PERFORMANCE_ID] = "0",
    [TEXTBOX_SKILL_DECEPTION_ID] = "0",
    [TEXTBOX_SKILL_INTIMIDATION_ID] = "0",
    [TEXTBOX_SKILL_PERSUASION_ID] = "0",
}

-- Индексы кнопок TTS по идентификатору элемента (checkbox/counter/display/roll/textbox-заглушки)
local btnIndexByElementIdTable = {}
-- Индексы текстовых полей (input) TTS по идентификатору textbox.
-- Используется только для точечной коррекции значения (см. updateLevelByExp) —
-- у self.editInput НЕТ параметра id, только числовой index, поэтому такая
-- таблица обязательна. Безопасна, поскольку self.createInput вызывается
-- только в createTextbox(), всегда единым проходом сразу после self.clearInputs().
local inputIndexByElementIdTable = {}
-- Счётчик заспавненных кнопок чекбоксов/счётчиков (используется в onload,
-- createCheckbox и createCounter). Объявлена здесь один раз как local,
-- чтобы функции ниже делили одну и ту же переменную (upvalue), а не глобальную.
local spawnedButtonCount = 0

-- Таблица расположения и параметров всех элементов листа персонажа
defaultButtonData = {
    -- Чекбоксы
    checkbox = {
  --[[
  pos   = позиция (вставляется из вспомогательного инструмента позиционирования)
  size  = высота/ширина/размер шрифта чекбокса
  state = стартовое значение чекбокса (true = отмечен, false = нет)
  ]]
  [CHECKBOX_SKILL_STR_SAVETHROW_ID] = {
skillId = SKILL_STR_SAVETHROW_ID,
pos     = {-1.123,0.1,-1.155},
size    = 150,
state   = false
  },
  [CHECKBOX_SKILL_ATHLETICS_ID] = {
skillId = SKILL_ATHLETICS_ID,
pos     = {-1.123,0.1,-1.10},
size    = 150,
state   = false
  },
  [CHECKBOX_SKILL_DEX_SAVETHROW_ID] = {
skillId = SKILL_DEX_SAVETHROW_ID,
pos     = {-1.123,0.1,-0.79},
size    = 150,
state   = false
  },
  [CHECKBOX_SKILL_ACROBATICS_ID] = {
skillId = SKILL_ACROBATICS_ID,
pos     = {-1.123,0.1,-0.735},
size    = 150,
state   = false
  },
  [CHECKBOX_SKILL_STEALTH_ID] = {
skillId = SKILL_STEALTH_ID,
pos     = {-1.123,0.1,-0.685},
size    = 150,
state   = false
  },
  [CHECKBOX_SKILL_SLEIGHT_OF_HAND_ID] = {
skillId = SKILL_SLEIGHT_OF_HAND_ID,
pos     = {-1.123,0.1,-0.630},
size    = 150,
state   = false
  },
  [CHECKBOX_SKILL_CON_SAVETHROW_ID] = {
skillId = SKILL_CON_SAVETHROW_ID,
pos     = {-1.123,0.1,-0.428},
size    = 150,
state   = false
  },
  [CHECKBOX_SKILL_INT_SAVETHROW_ID] = {
skillId = SKILL_INT_SAVETHROW_ID,
pos     = {-1.123,0.1,-0.070},
size    = 150,
state   = false
  },
  [CHECKBOX_SKILL_ARCANA_ID] = {
skillId = SKILL_ARCANA_ID,
pos     = {-1.123,0.1,-0.015},
size    = 150,
state   = false
  },
  [CHECKBOX_SKILL_HISTORY_ID] = {
skillId = SKILL_HISTORY_ID,
pos     = {-1.123,0.1,0.040},
size    = 150,
state   = false
  },
  [CHECKBOX_SKILL_INVESTIGATION_ID] = {
skillId = SKILL_INVESTIGATION_ID,
pos     = {-1.123,0.1,0.095},
size    = 150,
state   = false
  },
  [CHECKBOX_SKILL_NATURE_ID] = {
skillId = SKILL_NATURE_ID,
pos     = {-1.123,0.1,0.150},
size    = 150,
state   = false
  },
  [CHECKBOX_SKILL_RELIGION_ID] = {
skillId = SKILL_RELIGION_ID,
pos     = {-1.123,0.1,0.202},
size    = 150,
state   = false
  },
  [CHECKBOX_SKILL_WIS_SAVETHROW_ID] = {
skillId = SKILL_WIS_SAVETHROW_ID,
pos     = {-1.123,0.1,0.30},
size    = 150,
state   = false
  },
  [CHECKBOX_SKILL_ANIMAL_HANDLING_ID] = {
skillId = SKILL_ANIMAL_HANDLING_ID,
pos     = {-1.123,0.1,0.355},
size    = 150,
state   = false
  },
  [CHECKBOX_SKILL_INSIGHT_ID] = {
skillId = SKILL_INSIGHT_ID,
pos     = {-1.123,0.1,0.410},
size    = 150,
state   = false
  },
  [CHECKBOX_SKILL_MEDICINE_ID] = {
skillId = SKILL_MEDICINE_ID,
pos     = {-1.123,0.1,0.46},
size    = 150,
state   = false
  },
  [CHECKBOX_SKILL_PERCEPTION_ID] = {
skillId = SKILL_PERCEPTION_ID,
pos     = {-1.123,0.1,0.51},
size    = 150,
state   = false
  },
  [CHECKBOX_SKILL_SURVIVAL_ID] = {
skillId = SKILL_SURVIVAL_ID,
pos     = {-1.123,0.1,0.565},
size    = 150,
state   = false
  },
  [CHECKBOX_SKILL_CHA_SAVETHROW_ID] = {
skillId = SKILL_CHA_SAVETHROW_ID,
pos     = {-1.123,0.1,0.67},
size    = 150,
state   = false
  },
  [CHECKBOX_SKILL_PERFORMANCE_ID] = {
skillId = SKILL_PERFORMANCE_ID,
pos     = {-1.123,0.1,0.725},
size    = 150,
state   = false
  },
  [CHECKBOX_SKILL_DECEPTION_ID] = {
skillId = SKILL_DECEPTION_ID,
pos     = {-1.123,0.1,0.775},
size    = 150,
state   = false
  },
  [CHECKBOX_SKILL_INTIMIDATION_ID] = {
skillId = SKILL_INTIMIDATION_ID,
pos     = {-1.123,0.1,0.82},
size    = 150,
state   = false
  },
  [CHECKBOX_SKILL_PERSUASION_ID] = {
skillId = SKILL_PERSUASION_ID,
pos     = {-1.123,0.1,0.875},
size    = 150,
state   = false
  },
  [CHECKBOX_LIGHT_ARMOR_ID] = {
skillId = nil,
pos     = {-1.430,0.1,1.26},
size    = 150,
state   = false
  },
  [CHECKBOX_MEDIUM_ARMOR_ID] = {
skillId = nil,
pos     = {-1.430,0.1,1.30},
size    = 150,
state   = false
  },
  [CHECKBOX_HEAVY_ARMOR_ID] = {
skillId = nil,
pos     = {-1.430,0.1,1.34},
size    = 150,
state   = false
  },
  [CHECKBOX_SHIELD_ID] = {
skillId = nil,
pos     = {-1.430,0.1,1.38},
size    = 150,
state   = false
  },
  [CHECKBOX_SIMPLE_WEAPONS_ID] = {
skillId = nil,
pos     = {-1.2,0.1,1.26},
size    = 150,
state   = false
  },
  [CHECKBOX_MARTIAL_WEAPONS_ID] = {
skillId = nil,
pos     = {-1.2,0.1,1.30},
size    = 150,
state   = false
  },
  [CHECKBOX_DEATH_SAVETHROW_SUCCESS_1_ID] = {
skillId = nil,
pos     = {0.831,0.1,-1.085},
size    = 200,
state   = false
  },
  [CHECKBOX_DEATH_SAVETHROW_SUCCESS_2_ID] = {
skillId = nil,
pos     = {0.898,0.1,-1.085},
size    = 200,
state   = false
  },
  [CHECKBOX_DEATH_SAVETHROW_SUCCESS_3_ID] = {
skillId = nil,
pos     = {0.965,0.1,-1.085},
size    = 200,
state   = false
  },
  [CHECKBOX_DEATH_SAVETHROW_FAIL_1_ID] = {
skillId = nil,
pos     = {0.831,0.1,-1.017},
size    = 200,
state   = false
  },
  [CHECKBOX_DEATH_SAVETHROW_FAIL_2_ID] = {
skillId = nil,
pos     = {0.898,0.1,-1.017},
size    = 200,
state   = false
  },
  [CHECKBOX_DEATH_SAVETHROW_FAIL_3_ID] = {
skillId = nil,
pos     = {0.965,0.1,-1.017},
size    = 200,
state   = false
  },
  [CHECKBOX_WEIGHT_CAPACITY_X_2] = {
skillId = nil,
pos     = {0.392,0.1,1.937},
size    = 150,
state   = false
  },
  -- Конец чекбоксов
    },
    -- Счётчики характеристик (с кнопками + и -)
    counter = {
  --[[
  pos    = позиция (вставляется из вспомогательного инструмента позиционирования)
  size   = высота/ширина/размер шрифта счётчика
  value  = стартовое значение счётчика
  hideBG = скрыт ли фон счётчика (true = скрыт, false = нет)
  ]]

  [COUNTER_PARAM_STR_ID] = {
btnAddId = "counter_btn_add_"..PARAM_STR_ID,
btnSubId = "counter_btn_sub_"..PARAM_STR_ID,
hideBG   = true,
paramId  = PARAM_STR_ID,
pos= {-1.35,0.1,-1.025},
size     = 450,
value    = 10,
  },
  [COUNTER_PARAM_DEX_ID] = {
btnAddId = "counter_btn_add_"..PARAM_DEX_ID,
btnSubId = "counter_btn_sub_"..PARAM_DEX_ID,
hideBG   = true,
paramId  = PARAM_DEX_ID,
pos= {-1.35,0.1,-0.662},
size     = 450,
value    = 10,
  },
  [COUNTER_PARAM_CON_ID] = {
btnAddId = "counter_btn_add_"..PARAM_CON_ID,
btnSubId = "counter_btn_sub_"..PARAM_CON_ID,
hideBG   = true,
paramId  = PARAM_CON_ID,
pos= {-1.35,0.1,-0.299},
size     = 450,
value    = 10,
  },
  [COUNTER_PARAM_INT_ID] = {
btnAddId = "counter_btn_add_"..PARAM_INT_ID,
btnSubId = "counter_btn_sub_"..PARAM_INT_ID,
hideBG   = true,
paramId  = PARAM_INT_ID,
pos= {-1.35,0.1,0.064},
size     = 450,
value    = 10,
  },
  [COUNTER_PARAM_WIS_ID] = {
btnAddId = "counter_btn_add_"..PARAM_WIS_ID,
btnSubId = "counter_btn_sub_"..PARAM_WIS_ID,
hideBG   = true,
paramId  = PARAM_WIS_ID,
pos= {-1.35,0.1,0.427},
size     = 450,
value    = 10,
  },
  [COUNTER_PARAM_CHA_ID] = {
btnAddId = "counter_btn_add_"..PARAM_CHA_ID,
btnSubId = "counter_btn_sub_"..PARAM_CHA_ID,
hideBG   = true,
paramId  = PARAM_CHA_ID,
pos= {-1.35,0.1,0.790},
size     = 450,
value    = 10,
  },

  -- Конец счётчиков
    },
    -- Дисплеи (нередактируемые вычисляемые значения: модификаторы, бонусы навыков и т.д.)
    display = {
  --[[
  pos    = позиция (вставляется из вспомогательного инструмента позиционирования)
  size   = высота/ширина/размер шрифта дисплея
  value  = стартовое значение дисплея
  hideBG = скрыт ли фон дисплея (true = скрыт, false = нет)
  ]]
  [DISPLAY_PARAM_STR_ID] = {
paramId = PARAM_STR_ID,
pos     = {-1.35,0.1,-1.14},
size    = 450,
value   = 0,
hideBG  = true
  },
  [DISPLAY_PARAM_DEX_ID] = {
paramId = PARAM_DEX_ID,
pos     = {-1.35,0.1,-0.77},
size    = 450,
value   = 0,
hideBG  = true
  },
  [DISPLAY_PARAM_CON_ID] = {
paramId = PARAM_CON_ID,
pos     = {-1.35,0.1,-0.41},
size    = 450,
value   = 0,
hideBG  = true
  },
  [DISPLAY_PARAM_INT_ID] = {
paramId = PARAM_INT_ID,
pos     = {-1.35,0.1,-0.05},
size    = 450,
value   = 0,
hideBG  = true
  },
  [DISPLAY_PARAM_WIS_ID] = {
paramId = PARAM_WIS_ID,
pos     = {-1.35,0.1,0.31},
size    = 450,
value   = 0,
hideBG  = true
  },
  [DISPLAY_PARAM_CHA_ID] = {
paramId = PARAM_CHA_ID,
pos     = {-1.35,0.1,0.68},
size    = 450,
value   = 0,
hideBG  = true
  },
  [DISPLAY_SKILL_STR_SAVETHROW_ID] = {
skillId = SKILL_STR_SAVETHROW_ID,
pos     = {-0.973,0.1,-1.16},
size    = 250,
value   = 0,
hideBG  = true
  },
  [DISPLAY_SKILL_ATHLETICS_ID] = {
skillId = SKILL_ATHLETICS_ID,
pos     = {-0.973,0.1,-1.11},
size    = 250,
value   = 0,
hideBG  = true
  },
  [DISPLAY_SKILL_DEX_SAVETHROW_ID] = {
skillId = SKILL_DEX_SAVETHROW_ID,
pos     = {-0.973,0.1,-0.795},
size    = 250,
value   = 0,
hideBG  = true
  },
  [DISPLAY_SKILL_ACROBATICS_ID] = {
skillId = SKILL_ACROBATICS_ID,
pos     = {-0.973,0.1,-0.745},
size    = 250,
value   = 0,
hideBG  = true
  },
  [DISPLAY_SKILL_STEALTH_ID] = {
skillId = SKILL_STEALTH_ID,
pos     = {-0.973,0.1,-0.695},
size    = 250,
value   = 0,
hideBG  = true
  },
  [DISPLAY_SKILL_SLEIGHT_OF_HAND_ID] = {
skillId = SKILL_SLEIGHT_OF_HAND_ID,
pos     = {-0.973,0.1,-0.645},
size    = 250,
value   = 0,
hideBG  = true
  },
  [DISPLAY_SKILL_CON_SAVETHROW_ID] = {
skillId = SKILL_CON_SAVETHROW_ID,
pos     = {-0.973,0.1,-0.435},
size    = 250,
value   = 0,
hideBG  = true
  },
  [DISPLAY_SKILL_INT_SAVETHROW_ID] = {
skillId = SKILL_INT_SAVETHROW_ID,
pos     = {-0.973,0.1,-0.07},
size    = 250,
value   = 0,
hideBG  = true
  },
  [DISPLAY_SKILL_ARCANA_ID] = {
skillId = SKILL_ARCANA_ID,
pos     = {-0.973,0.1,-0.0215},
size    = 250,
value   = 0,
hideBG  = true
  },
  [DISPLAY_SKILL_HISTORY_ID] = {
skillId = SKILL_HISTORY_ID,
pos     = {-0.973,0.1,0.031},
size    = 250,
value   = 0,
hideBG  = true
  },
  [DISPLAY_SKILL_INVESTIGATION_ID] = {
skillId = SKILL_INVESTIGATION_ID,
pos     = {-0.973,0.1,0.0825},
size    = 250,
value   = 0,
hideBG  = true
  },
  [DISPLAY_SKILL_NATURE_ID] = {
skillId = SKILL_NATURE_ID,
pos     = {-0.973,0.1,0.135},
size    = 250,
value   = 0,
hideBG  = true
  },
  [DISPLAY_SKILL_RELIGION_ID] = {
skillId = SKILL_RELIGION_ID,
pos     = {-0.973,0.1,0.185},
size    = 250,
value   = 0,
hideBG  = true
  },
  [DISPLAY_SKILL_WIS_SAVETHROW_ID] = {
skillId = SKILL_WIS_SAVETHROW_ID,
pos     = {-0.973,0.1,0.295},
size    = 250,
value   = 0,
hideBG  = true
  },
  [DISPLAY_SKILL_ANIMAL_HANDLING_ID] = {
skillId = SKILL_ANIMAL_HANDLING_ID,
pos     = {-0.973,0.1,0.345},
size    = 250,
value   = 0,
hideBG  = true
  },
  [DISPLAY_SKILL_INSIGHT_ID] = {
skillId = SKILL_INSIGHT_ID,
pos     = {-0.973,0.1,0.395},
size    = 250,
value   = 0,
hideBG  = true
  },
  [DISPLAY_SKILL_MEDICINE_ID] = {
skillId = SKILL_MEDICINE_ID,
pos     = {-0.973,0.1,0.445},
size    = 250,
value   = 0,
hideBG  = true
  },
  [DISPLAY_SKILL_PERCEPTION_ID] = {
skillId = SKILL_PERCEPTION_ID,
pos     = {-0.973,0.1,0.495},
size    = 250,
value   = 0,
hideBG  = true
  },
  [DISPLAY_SKILL_SURVIVAL_ID] = {
skillId = SKILL_SURVIVAL_ID,
pos     = {-0.973,0.1,0.55},
size    = 250,
value   = 0,
hideBG  = true
  },
  [DISPLAY_SKILL_CHA_SAVETHROW_ID] = {
skillId = SKILL_CHA_SAVETHROW_ID,
pos     = {-0.973,0.1,0.66},
size    = 250,
value   = 0,
hideBG  = true
  },
  [DISPLAY_SKILL_PERFORMANCE_ID] = {
skillId = SKILL_PERFORMANCE_ID,
pos     = {-0.973,0.1,0.708},
size    = 250,
value   = 0,
hideBG  = true
  },
  [DISPLAY_SKILL_DECEPTION_ID] = {
skillId = SKILL_DECEPTION_ID,
pos     = {-0.973,0.1,0.76},
size    = 250,
value   = 0,
hideBG  = true
  },
  [DISPLAY_SKILL_INTIMIDATION_ID] = {
skillId = SKILL_INTIMIDATION_ID,
pos     = {-0.973,0.1,0.813},
size    = 250,
value   = 0,
hideBG  = true
  },
  [DISPLAY_SKILL_PERSUASION_ID] = {
skillId = SKILL_PERSUASION_ID,
pos     = {-0.973,0.1,0.863},
size    = 250,
value   = 0,
hideBG  = true
  },
  [DISPLAY_PASSIVE_PERCEPTION_ID] = {
pos    = {-1.35,0.1,1.03},
size   = 450,
value  = 10,
hideBG = true,
  },
  [DISPLAY_WEIGHT_CAPACITY_ID] = {
pos    = {-0.225,0.1,2.085},
size   = 450,
value  = 150,
hideBG = true,
  },
  [DISPLAY_RAISE_LIFT_AND_PULL_ID] = {
pos    = {0.225,0.1,2.085},
size   = 450,
value  = 300,
hideBG = true,
  },
  [DISPLAY_JUMP_HEIGHT_ID] = {
pos    = {0.05,0.1,1.76},
size   = 350,
value  = 3,
hideBG = true,
  },
  [DISPLAY_JUMP_DISTANCE_ID] = {
pos    = {0.05,0.1,1.695},
size   = 350,
value  = 10,
hideBG = true,
  },
  [DISPLAY_JUMP_HEIGHT_WITH_HANDS_ID] = {
pos    = {0.05,0.1,1.825},
size   = 350,
value  = 3,
hideBG = true,
  },
  [DISPLAY_JUMP_HEIGHT_NO_RUNNING_ID] = {
pos    = {0.34,0.1,1.76},
size   = 350,
value  = 1,
hideBG = true,
  },
  [DISPLAY_JUMP_DISTANCE_NO_RUNNING_ID] = {
pos    = {0.34,0.1,1.695},
size   = 350,
value  = 5,
hideBG = true,
  },
  [DISPLAY_JUMP_HEIGHT_WITH_HANDS_NO_RUNNING_ID] = {
pos     = {0.34,0.1,1.825},
size   = 350,
value  = 1,
hideBG = true,
  },
  [DISPLAY_LEVEL_ID] = {
pos    = {-1.35,0.1,-1.285},
size   = 600,
value  = 1,
hideBG = true,
  },
  [DISPLAY_NEXT_LVL_ID] = {
pos    = {1.27,0.1,-1.835},
size   = 300,
value  = '/ 300',
hideBG = true,
  },
  [DISPLAY_PROFICIENCY_ID] = {
pos    = {-1.35,0.1,-1.45},
size   = 650,
value  = '+2',
hideBG = true,
  },
  [DISPLAY_HIT_DICES_LEFT_ID] = {
pos    = {0.75,0.1,-1.38},
size   = 450,
value  = ' 1/ 1к',
hideBG = true,
  },
  [DISPLAY_MONET_WEIGHT_ID] = {
pos    = {-0.22,0.11,0.713},
size   = 150,
value  = NET_MONET_TEXT,
hideBG = true,
  },
  -- Конец дисплеев
    },

      select = { -- Блок для выбора заклинательной характеристики
    [SELECT_SPELLCASTING_ABILITY_ID] = { -- 2 Заклинательная характеристика
pos = {0.077,0.1,0.48}, -- та же позиция, что была у поля-текстбокса
rows= 1,
width     = 1500,
font_size = 450,
height    = 630,
value     = PARAM_INT_ID, -- характеристика по умолчанию
    },
  },
    -- Редактируемые текстовые поля
    textbox = {
  --[[
  pos       = позиция (вставляется из вспомогательного инструмента позиционирования)
  rows      = количество строк текста в поле
  width     = ширина текстового поля
  font_size = размер шрифта. Вместе с "rows" влияет на итоговую высоту поля
  value     = текст в поле по умолчанию. "" = пусто
  alignment = выравнивание текста
              (1 = автоматически, 2 = слева, 3 = по центру, 4 = справа, 5 = по ширине)
  validation = тип валидации ввода (2 = число и т.п. — см. документацию TTS createInput)
  ]]
  [TEXTBOX_NAME_ID] = {
pos = {-0.825,0.1,-1.900},
rows= 1,
width     = 5000,
font_size = 350,
value     = "",
alignment = 3
  },
  [TEXTBOX_CLASS_LEVEL_ID] = {
pos = {0.075,0.1,-1.975},
rows= 1,
width     = 2500,
font_size = 350,
value     = "",
alignment = 3
  },
  [TEXTBOX_BACKGROUND_ID] = {
pos = {0.612,0.1,-1.975},
rows= 1,
width     = 2600,
font_size = 350,
value     = "",
alignment = 3
  },
  [TEXTBOX_PLAYERS_NAME_ID] = {
pos = {1.14,0.1,-1.975},
rows= 1,
width     = 2400,
font_size = 350,
value     = "",
alignment = 3
  },
  [TEXTBOX_RACE_ID] = {
pos = {0.075,0.1,-1.835},
rows= 1,
width     = 2500,
font_size = 350,
value     = "",
alignment = 3
  },
  [TEXTBOX_ALIGMENT_ID] = {
pos = {0.612,0.1,-1.835},
rows= 1,
width     = 2600,
font_size = 350,
value     = "",
alignment = 3
  },
  [TEXTBOX_XP_ID] = {
pos  = {1.015,0.1,-1.835},
rows = 1,
width= 1200,
font_size  = 350,
value= "0",
alignment  = 3,
validation = 2,
  },
  [TEXTBOX_AGE_ID] = {
pos  = {-0.671,0.1,1.24},
rows = 1,
width= 1200,
font_size  = 300,
value= "0",
alignment  = 3,
validation = 2,
  },
  [TEXTBOX_AC_ID] = {
pos  = {-0.265,0.1,-1.425},
rows = 1,
width= 750,
font_size  = 450,
value= "10",
alignment  = 3,
validation = 2,
  },
  [TEXTBOX_HIT_DICES_ID] = {
pos  = {0.93,0.1,-1.38},
rows = 1,
width= 500,
font_size  = 450,
value= "",
alignment  = 1,
validation = 2,
  },
  [TEXTBOX_INITIATIVE_ID] = {
pos = {1.25,0.1,-1.45},
rows= 1,
width     = 750,
font_size = 450,
value     = "",
alignment = 3
  },
  [TEXTBOX_SPEED_ID] = {
pos = {1.25,0.1,-1.225},
rows= 1,
width     = 1000,
font_size = 450,
value     = "",
alignment = 3
  },
  [TEXTBOX_VISION_ID] = {
pos = {1.25,0.1,-1.0},
rows= 1,
width     = 1500,
font_size = 300,
value     = "",
alignment = 3
  },
  [TEXTBOX_WEAPON_NAME_1_ID] = {
pos = {-0.08,0.1,-0.71 },
rows= 1,
width     = 3350,
font_size = 300,
value     = "",
alignment = 3
  },
  [TEXTBOX_WEAPON_NAME_2_ID] = {
pos = {-0.08,0.1,-0.632},
rows= 1,
width     = 3350,
font_size = 300,
value     = "",
alignment = 3
  },
  [TEXTBOX_WEAPON_NAME_3_ID] = {
pos = {-0.08,0.1,-0.554},
rows= 1,
width     = 3350,
font_size = 300,
value     = "",
alignment = 3
  },
  [TEXTBOX_WEAPON_NAME_4_ID] = {
pos = {-0.08,0.1,-0.476},
rows= 1,
width     = 3350,
font_size = 310,
value     = "",
alignment = 3
  },
  [TEXTBOX_WEAPON_NAME_5_ID] = {
pos = {-0.08,0.1,-0.398},
rows= 1,
width     = 3350,
font_size = 310,
value     = "",
alignment = 3
  },
  [TEXTBOX_WEAPON_NAME_6_ID] = {
pos = {-0.08,0.1,-0.320},
rows= 1,
width     = 3350,
font_size = 310,
value     = "",
alignment = 3
  },
  [TEXTBOX_WEAPON_NAME_7_ID] = {
pos = {-0.08,0.1,-0.242},
rows= 1,
width     = 3350,
font_size = 310,
value     = "",
alignment = 3
  },
  [TEXTBOX_HIT_1_ID] = {
pos = {0.375, 0.1, -0.71},
rows= 1,
width     = 800,
font_size = 300,
value     = "",
alignment = 2,
  },
  [TEXTBOX_HIT_2_ID] = {
pos = {0.375, 0.1, -0.632},
rows= 1,
width     = 800,
font_size = 300,
value     = "",
alignment = 2,
  },
  [TEXTBOX_HIT_3_ID] = {
pos = {0.375, 0.1, -0.554},
rows= 1,
width     = 800,
font_size = 300,
value     = "",
alignment = 2,
  },
  [TEXTBOX_HIT_4_ID] = {
pos = {0.375, 0.1, -0.476},
rows= 1,
width     = 800,
font_size = 300,
value     = "",
alignment = 2,
  },
  [TEXTBOX_HIT_5_ID] = {
pos = {0.375, 0.1, -0.398},
rows= 1,
width     = 800,
font_size = 300,
value     = "",
alignment = 2,
  },
  [TEXTBOX_HIT_6_ID] = {
pos = {0.375, 0.1, -0.320},
rows= 1,
width     = 800,
font_size = 300,
value     = "",
alignment = 2,
  },
  [TEXTBOX_HIT_7_ID] = {
pos = {0.375, 0.1, -0.242},
rows= 1,
width     = 800,
font_size = 300,
value     = "",
alignment = 2,
  },
  [TEXTBOX_DAMAGE_DICE_COUNT_1_ID] = {
pos  = {0.5155,0.1,-0.71},
rows = 1,
width= 420,
font_size  = 300,
value= "",
alignment  = 4,
validation = 2,
  },
  [TEXTBOX_DAMAGE_DICE_COUNT_2_ID] = {
pos  = {0.5155,0.1,-0.632},
rows = 1,
width= 420,
font_size  = 300,
value= "",
alignment  = 4,
validation = 2,
  },
  [TEXTBOX_DAMAGE_DICE_COUNT_3_ID] = {
pos  = {0.5155,0.1,-0.554},
rows = 1,
width= 420,
font_size  = 300,
value= "",
alignment  = 4,
validation = 2,
  },
  [TEXTBOX_DAMAGE_DICE_COUNT_4_ID] = {
pos  = {0.5155,0.1,-0.476},
rows = 1,
width= 420,
font_size  = 300,
value= "",
alignment  = 4,
validation = 2,
  },
  [TEXTBOX_DAMAGE_DICE_COUNT_5_ID] = {
pos  = {0.5155,0.1,-0.398},
rows = 1,
width= 420,
font_size  = 300,
value= "",
alignment  = 4,
validation = 2,
  },
  [TEXTBOX_DAMAGE_DICE_COUNT_6_ID] = {
pos  = {0.5155,0.1,-0.320},
rows = 1,
width= 420,
font_size  = 300,
value= "",
alignment  = 4,
validation = 2,
  },
  [TEXTBOX_DAMAGE_DICE_COUNT_7_ID] = {
pos  = {0.5155,0.1,-0.242},
rows = 1,
width= 420,
font_size  = 300,
value= "",
alignment  = 4,
validation = 2,
  },
  [TEXTBOX_DAMAGE_DICE_TYPE_1_ID] = {
pos  = {0.625,0.1,-0.71},
rows = 1,
width= 400,
font_size  = 300,
value= "",
alignment  = 2,
validation = 2,
  },
  [TEXTBOX_DAMAGE_DICE_TYPE_2_ID] = {
pos  = {0.625,0.1,-0.632},
rows = 1,
width= 400,
font_size  = 300,
value= "",
alignment  = 2,
validation = 2,
  },
  [TEXTBOX_DAMAGE_DICE_TYPE_3_ID] = {
pos  = {0.625,0.1,-0.554},
rows = 1,
width= 400,
font_size  = 300,
value= "",
alignment  = 2,
validation = 2,
  },
  [TEXTBOX_DAMAGE_DICE_TYPE_4_ID] = {
pos  = {0.625,0.1,-0.476},
rows = 1,
width= 400,
font_size  = 300,
value= "",
alignment  = 2,
validation = 2,
  },
  [TEXTBOX_DAMAGE_DICE_TYPE_5_ID] = {
pos  = {0.625,0.1,-0.398},
rows = 1,
width= 400,
font_size  = 300,
value= "",
alignment  = 2,
validation = 2,
  },
  [TEXTBOX_DAMAGE_DICE_TYPE_6_ID] = {
pos  = {0.625,0.1,-0.320},
rows = 1,
width= 400,
font_size  = 300,
value= "",
alignment  = 2,
validation = 2,
  },
  [TEXTBOX_DAMAGE_DICE_TYPE_7_ID] = {
pos  = {0.625,0.1,-0.242},
rows = 1,
width= 400,
font_size  = 300,
value= "",
alignment  = 2,
validation = 2,
  },
  [TEXTBOX_DAMAGE_BONUS_1_ID] = {
pos = {-0.205 + 0.9475,0.1,-0.71},
rows= 1,
width     = 600,
font_size = 300,
value     = "",
alignment = 2,
  },
  [TEXTBOX_DAMAGE_BONUS_2_ID] = {
pos = {-0.205 + 0.9475,0.1,-0.632},
rows= 1,
width     = 600,
font_size = 300,
value     = "",
alignment = 2,
  },
  [TEXTBOX_DAMAGE_BONUS_3_ID] = {
pos = {-0.205 + 0.9475,0.1,-0.554},
rows= 1,
width     = 600,
font_size = 300,
value     = "",
alignment = 2,
  },
  [TEXTBOX_DAMAGE_BONUS_4_ID] = {
pos = {-0.205 + 0.9475,0.1,-0.476},
rows= 1,
width     = 600,
font_size = 300,
value     = "",
alignment = 2,
  },
  [TEXTBOX_DAMAGE_BONUS_5_ID] = {
pos = {-0.205 + 0.9475,0.1,-0.398},
rows= 1,
width     = 600,
font_size = 300,
value     = "",
alignment = 2,
  },
  [TEXTBOX_DAMAGE_BONUS_6_ID] = {
pos = {-0.205 + 0.9475,0.1,-0.320},
rows= 1,
width     = 600,
font_size = 300,
value     = "",
alignment = 2,
  },
  [TEXTBOX_DAMAGE_BONUS_7_ID] = {
pos = {-0.205 + 0.9475,0.1,-0.242},
rows= 1,
width     = 600,
font_size = 300,
value     = "",
alignment = 2,
  },
  [TEXTBOX_NOTES_1_ID] = {
pos = {-0.151 + 1.29,0.1,-0.71},
rows= 1,
width     = 3100,
font_size = 300,
value     = "",
alignment = 3
  },

  [TEXTBOX_NOTES_2_ID] = {
pos = {-0.151 + 1.29,0.1,-0.632},
rows= 1,
width     = 3100,
font_size = 300,
value     = "",
alignment = 3
  },
  [TEXTBOX_NOTES_3_ID] = {
pos = {-0.151 + 1.29,0.1,-0.554},
rows= 1,
width     = 3100,
font_size = 300,
value     = "",
alignment = 3
  },
  [TEXTBOX_NOTES_4_ID] = {
pos = {-0.151 + 1.29,0.1,-0.476},
rows= 1,
width     = 3100,
font_size = 300,
value     = "",
alignment = 3
  },
  [TEXTBOX_NOTES_5_ID] = {
pos = {-0.151 + 1.29,0.1,-0.398},
rows= 1,
width     = 3100,
font_size = 300,
value     = "",
alignment = 3
  },
  [TEXTBOX_NOTES_6_ID] = {
pos = {-0.151 + 1.29,0.1,-0.320},
rows= 1,
width     = 3100,
font_size = 300,
value     = "",
alignment = 3
  },
  [TEXTBOX_NOTES_7_ID] = {
pos = {-0.151 + 1.29,0.1,-0.242},
rows= 1,
width     = 3100,
font_size = 300,
value     = "",
alignment = 3
  },
  [TEXTBOX_EQUIPMENT_ID] = { -- Снаряжение (было textbox_Equipment_2)
pos = {0.015,0.1,1.1},
rows= 13,
width     = 4425,
font_size = 300,
value     = "",
alignment = 2
  },
  [TEXTBOX_SPELL_CLASS_ID] = { -- 1 Класс заклинателя
pos = {0.4,0.1,0.17},
rows= 1,
width     = 5000,
font_size = 400,
value     = "",
alignment = 3
  },
  [TEXTBOX_SPELL_SAVE_DC_ID] = { -- 3 Сложность спасброска (x+y+z)
pos = {0.521,0.1,0.48},
rows= 1,
width     = 1500,
font_size = 450,
value     = "",
alignment = 3
  },
  [TEXTBOX_SPELL_ATTACK_BONUS_ID] = { -- 4 Бонус атаки заклинанием (x+y+z)
pos = {1.032,0.1,0.48},
rows= 1,
width     = 1500,
font_size = 450,
value     = "",
alignment = 3
  },
  [TEXTBOX_CLASS_RACE_CHARACTERISTICS_ID] = {
pos = {1.014,0.1,1.425},
rows= 28,
width     = 4550,
font_size = 250,
value     = "",
alignment = 2
  },
  [TEXTBOX_HEIGHT_ID] = {
pos  = {-0.671,0.1,1.315},
rows = 1,
width= 1200,
font_size  = 300,
value= "0",
alignment  = 3,
validation = 3,
  },
  [TEXTBOX_WEIGHT_ID] = {
pos  = {-0.671,0.1,1.39},
rows = 1,
width= 1200,
font_size  = 300,
value= "0",
alignment  = 3,
validation = 2,
  },
  [TEXTBOX_PROFICIENCY_OTHER_ID] = {
pos = {-1,0.1,1.78},
rows= 10,
width     = 4350,
font_size = 300,
value     = "",
alignment = 2
  },
  [TEXTBOX_SKILL_STR_SAVETHROW_ID] = {
skillId    = SKILL_STR_SAVETHROW_ID,
pos  = {-1.055,0.1,-1.165},
rows = 1,
width= TEXTBOX_SKILL_width,
font_size  = TEXTBOX_SKILL_fontSize,
value= "0",
alignment  = 3,
validation = 2,
  },
  [TEXTBOX_SKILL_ATHLETICS_ID] = {
skillId    = SKILL_ATHLETICS_ID,
pos  = {-1.055,0.1,-1.1105},
rows = 1,
width= TEXTBOX_SKILL_width,
font_size  = TEXTBOX_SKILL_fontSize,
value= "0",
alignment  = 3,
validation = 2,
  },
  [TEXTBOX_SKILL_DEX_SAVETHROW_ID] = {
skillId    = SKILL_DEX_SAVETHROW_ID,
pos  = {-1.055,0.1,-0.8},
rows = 1,
width= TEXTBOX_SKILL_width,
font_size  = TEXTBOX_SKILL_fontSize,
value= "0",
alignment  = 3,
validation = 2,
  },
  [TEXTBOX_SKILL_ACROBATICS_ID] = {
skillId    = SKILL_ACROBATICS_ID,
pos  = {-1.055,0.1,-0.745},
rows = 1,
width= TEXTBOX_SKILL_width,
font_size  = TEXTBOX_SKILL_fontSize,
value= "0",
alignment  = 3,
validation = 2,
  },
  [TEXTBOX_SKILL_STEALTH_ID] = {
skillId    = SKILL_STEALTH_ID,
pos  = {-1.055,0.1,-0.695},
rows = 1,
width= TEXTBOX_SKILL_width,
font_size  = TEXTBOX_SKILL_fontSize,
value= "0",
alignment  = 3,
validation = 2,
  },
  [TEXTBOX_SKILL_SLEIGHT_OF_HAND_ID] = {
skillId    = SKILL_SLEIGHT_OF_HAND_ID,
pos  = {-1.055,0.1,-0.645},
rows = 1,
width= TEXTBOX_SKILL_width,
font_size  = TEXTBOX_SKILL_fontSize,
value= "0",
alignment  = 3,
validation = 2,
  },
  [TEXTBOX_SKILL_CON_SAVETHROW_ID] = {
skillId    = SKILL_CON_SAVETHROW_ID,
pos  = {-1.055,0.1,-0.435},
rows = 1,
width= TEXTBOX_SKILL_width,
font_size  = TEXTBOX_SKILL_fontSize,
value= "0",
alignment  = 3,
validation = 2,
  },
  [TEXTBOX_SKILL_INT_SAVETHROW_ID] = {
skillId    = SKILL_INT_SAVETHROW_ID,
pos  = {-1.055,0.1,-0.075},
rows = 1,
width= TEXTBOX_SKILL_width,
font_size  = TEXTBOX_SKILL_fontSize,
value= "0",
alignment  = 3,
validation = 2,
  },
  [TEXTBOX_SKILL_ARCANA_ID] = {
skillId    = SKILL_ARCANA_ID,
pos  = {-1.055,0.1,-0.0215},
rows = 1,
width= TEXTBOX_SKILL_width,
font_size  = TEXTBOX_SKILL_fontSize,
value= "0",
alignment  = 3,
validation = 2,
  },
  [TEXTBOX_SKILL_HISTORY_ID] = {
skillId    = SKILL_HISTORY_ID,
pos  = {-1.055,0.1,0.031},
rows = 1,
width= TEXTBOX_SKILL_width,
font_size  = TEXTBOX_SKILL_fontSize,
value= "0",
alignment  = 3,
validation = 2,
  },
  [TEXTBOX_SKILL_INVESTIGATION_ID] = {
skillId    = SKILL_INVESTIGATION_ID,
pos  = {-1.055,0.1,0.0825},
rows = 1,
width= TEXTBOX_SKILL_width,
font_size  = TEXTBOX_SKILL_fontSize,
value= "0",
alignment  = 3,
validation = 2,
  },
  [TEXTBOX_SKILL_NATURE_ID] = {
skillId    = SKILL_NATURE_ID,
pos  = {-1.055,0.1,0.135},
rows = 1,
width= TEXTBOX_SKILL_width,
font_size  = TEXTBOX_SKILL_fontSize,
value= "0",
alignment  = 3,
validation = 2,
  },
  [TEXTBOX_SKILL_RELIGION_ID] = {
skillId    = SKILL_RELIGION_ID,
pos  = {-1.055,0.1,0.185},
rows = 1,
width= TEXTBOX_SKILL_width,
font_size  = TEXTBOX_SKILL_fontSize,
value= "0",
alignment  = 3,
validation = 2,
  },
  [TEXTBOX_SKILL_WIS_SAVETHROW_ID] = {
skillId    = SKILL_WIS_SAVETHROW_ID,
pos  = {-1.055,0.1,0.29},
rows = 1,
width= TEXTBOX_SKILL_width,
font_size  = TEXTBOX_SKILL_fontSize,
value= "0",
alignment  = 3,
validation = 2,
  },
  [TEXTBOX_SKILL_ANIMAL_HANDLING_ID] = {
skillId    = SKILL_ANIMAL_HANDLING_ID,
pos  = {-1.055,0.1,0.345},
rows = 1,
width= TEXTBOX_SKILL_width,
font_size  = TEXTBOX_SKILL_fontSize,
value= "0",
alignment  = 3,
validation = 2,
  },
  [TEXTBOX_SKILL_INSIGHT_ID] = {
skillId    = SKILL_INSIGHT_ID,
pos  = {-1.055,0.1,0.395},
rows = 1,
width= TEXTBOX_SKILL_width,
font_size  = TEXTBOX_SKILL_fontSize,
value= "0",
alignment  = 3,
validation = 2,
  },
  [TEXTBOX_SKILL_MEDICINE_ID] = {
skillId    = SKILL_MEDICINE_ID,
pos  = {-1.055,0.1,0.445},
rows = 1,
width= TEXTBOX_SKILL_width,
font_size  = TEXTBOX_SKILL_fontSize,
value= "0",
alignment  = 3,
validation = 2,
  },
  [TEXTBOX_SKILL_PERCEPTION_ID] = {
skillId    = SKILL_PERCEPTION_ID,
pos  = {-1.055,0.1,0.495},
rows = 1,
width= TEXTBOX_SKILL_width,
font_size  = TEXTBOX_SKILL_fontSize,
value= "0",
alignment  = 3,
validation = 2,
  },
  [TEXTBOX_SKILL_SURVIVAL_ID] = {
skillId    = SKILL_SURVIVAL_ID,
pos  = {-1.055,0.1,0.55},
rows = 1,
width= TEXTBOX_SKILL_width,
font_size  = TEXTBOX_SKILL_fontSize,
value= "0",
alignment  = 3,
validation = 2,
  },
  [TEXTBOX_SKILL_CHA_SAVETHROW_ID] = {
skillId    = SKILL_CHA_SAVETHROW_ID,
pos  = {-1.055,0.1,0.655},
rows = 1,
width= TEXTBOX_SKILL_width,
font_size  = TEXTBOX_SKILL_fontSize,
value= "0",
alignment  = 3,
validation = 2,
  },
  [TEXTBOX_SKILL_PERFORMANCE_ID] = {
skillId    = SKILL_PERFORMANCE_ID,
pos  = {-1.055,0.1,0.708},
rows = 1,
width= TEXTBOX_SKILL_width,
font_size  = TEXTBOX_SKILL_fontSize,
value= "0",
alignment  = 3,
validation = 2,
  },
  [TEXTBOX_SKILL_DECEPTION_ID] = {
skillId    = SKILL_DECEPTION_ID,
pos  = {-1.055,0.1,0.76},
rows = 1,
width= TEXTBOX_SKILL_width,
font_size  = TEXTBOX_SKILL_fontSize,
value= "0",
alignment  = 3,
validation = 2,
  },
  [TEXTBOX_SKILL_INTIMIDATION_ID] = {
skillId    = SKILL_INTIMIDATION_ID,
pos  = {-1.055,0.1,0.813},
rows = 1,
width= TEXTBOX_SKILL_width,
font_size  = TEXTBOX_SKILL_fontSize,
value= "0",
alignment  = 3,
validation = 2,
  },
  [TEXTBOX_SKILL_PERSUASION_ID] = {
skillId    = SKILL_PERSUASION_ID,
pos  = {-1.055,0.1,0.863},
rows = 1,
width= TEXTBOX_SKILL_width,
font_size  = TEXTBOX_SKILL_fontSize,
value= "0",
alignment  = 3,
validation = 2,
  },
  -- Конец текстовых полей
    },
    -- Кнопки бросков костей (характеристики и навыки)
    roll = {
  [ROLL_PARAM_STR_ID] = {
pos = {-1.355, 0.1, -0.95},
paramId   = PARAM_STR_ID,
width     = 1500,
font_size = 250,
  },
  [ROLL_PARAM_DEX_ID] = {
pos = {-1.355, 0.1, -0.584},
paramId   = PARAM_DEX_ID,
width     = 1500,
font_size = 250,
  },
  [ROLL_PARAM_CON_ID] = {
pos = {-1.355, 0.1, -0.218},
paramId   = PARAM_CON_ID,
width     = 1500,
font_size = 210,
  },
  [ROLL_PARAM_INT_ID] = {
pos = {-1.355, 0.1, 0.148},
paramId   = PARAM_INT_ID,
width     = 1500,
font_size = 250,
  },
  [ROLL_PARAM_WIS_ID] = {
pos = {-1.355, 0.1, 0.514},
paramId   = PARAM_WIS_ID,
width     = 1500,
font_size = 250,
  },
  [ROLL_PARAM_CHA_ID] = {
pos = {-1.355, 0.1, 0.88},
paramId   = PARAM_CHA_ID,
width     = 1500,
font_size = 250,
  },
  [ROLL_SKILL_STR_SAVETHROW_ID] = {
pos = {0.2 - 0.931, 0.1, -1.16+0.004},
skillId   = SKILL_STR_SAVETHROW_ID,
width     = 1950,
font_size = 180,
  },
  [ROLL_SKILL_ATHLETICS_ID] = {
pos = {0.2 - 0.931, 0.1, -1.11+0.004},
skillId   = SKILL_ATHLETICS_ID,
width     = 1950,
font_size = 180,
  },
  [ROLL_SKILL_DEX_SAVETHROW_ID] = {
pos = {0.2 - 0.931, 0.1, -0.795+0.004},
skillId   = SKILL_DEX_SAVETHROW_ID,
width     = 1950,
font_size = 180,
  },
  [ROLL_SKILL_ACROBATICS_ID] = {
pos = {0.2 - 0.931, 0.1, -0.745+0.004},
skillId   = SKILL_ACROBATICS_ID,
width     = 1950,
font_size = 180,
  },
  [ROLL_SKILL_STEALTH_ID] = {
pos = {0.2 - 0.931, 0.1, -0.695+0.004},
skillId   = SKILL_STEALTH_ID,
width     = 1950,
font_size = 180,
  },
  [ROLL_SKILL_SLEIGHT_OF_HAND_ID] = {
pos = {0.2 - 0.931, 0.1, -0.645+0.004},
skillId   = SKILL_SLEIGHT_OF_HAND_ID,
width     = 1950,
font_size = 180,
  },
  [ROLL_SKILL_CON_SAVETHROW_ID] = {
pos = {0.2 - 0.931, 0.1, -0.435+0.004},
skillId   = SKILL_CON_SAVETHROW_ID,
width     = 1950,
font_size = 180,
  },
  [ROLL_SKILL_INT_SAVETHROW_ID] = {
pos = {0.2 - 0.931, 0.1, -0.07+0.004},
skillId   = SKILL_INT_SAVETHROW_ID,
width     = 1950,
font_size = 180,
  },
  [ROLL_SKILL_ARCANA_ID] = {
pos = {0.2 - 0.931, 0.1, -0.0215+0.004},
skillId   = SKILL_ARCANA_ID,
width     = 1950,
font_size = 180,
  },
  [ROLL_SKILL_HISTORY_ID] = {
pos = {0.2 - 0.931, 0.1, 0.031+0.004},
skillId   = SKILL_HISTORY_ID,
width     = 1950,
font_size = 180,
  },
  [ROLL_SKILL_INVESTIGATION_ID] = {
pos = {0.2 - 0.931, 0.1, 0.0825+0.004},
skillId   = SKILL_INVESTIGATION_ID,
width     = 1950,
font_size = 180,
  },
  [ROLL_SKILL_NATURE_ID] = {
pos = {0.2 - 0.931, 0.1, 0.135+0.004},
skillId   = SKILL_NATURE_ID,
width     = 1950,
font_size = 180,
  },
  [ROLL_SKILL_RELIGION_ID] = {
pos = {0.2 - 0.931, 0.1, 0.185+0.004},
skillId   = SKILL_RELIGION_ID,
width     = 1950,
font_size = 180,
  },
  [ROLL_SKILL_WIS_SAVETHROW_ID] = {
pos = {0.2 - 0.931, 0.1, 0.295+0.004},
skillId   = SKILL_WIS_SAVETHROW_ID,
width     = 1950,
font_size = 180,
  },
  [ROLL_SKILL_ANIMAL_HANDLING_ID] = {
pos = {0.2 - 0.931, 0.1, 0.345+0.004},
skillId   = SKILL_ANIMAL_HANDLING_ID,
width     = 1950,
height    = 180*1.4,
font_size = 140,
  },
  [ROLL_SKILL_INSIGHT_ID] = {
pos = {0.2 - 0.931, 0.1, 0.395+0.004},
skillId   = SKILL_INSIGHT_ID,
width     = 1950,
font_size = 180,
  },
  [ROLL_SKILL_MEDICINE_ID] = {
pos = {0.2 - 0.931, 0.1, 0.445+0.004},
skillId   = SKILL_MEDICINE_ID,
width     = 1950,
font_size = 180,
  },
  [ROLL_SKILL_PERCEPTION_ID] = {
pos = {0.2 - 0.931, 0.1, 0.495+0.004},
skillId   = SKILL_PERCEPTION_ID,
width     = 1950,
font_size = 180,
  },
  [ROLL_SKILL_SURVIVAL_ID] = {
pos = {0.2 - 0.931, 0.1, 0.55+0.004},
skillId   = SKILL_SURVIVAL_ID,
width     = 1950,
font_size = 180,
  },
  [ROLL_SKILL_CHA_SAVETHROW_ID] = {
pos = {0.2 - 0.931, 0.1, 0.66+0.004},
skillId   = SKILL_CHA_SAVETHROW_ID,
width     = 1950,
font_size = 180,
  },
  [ROLL_SKILL_PERFORMANCE_ID] = {
pos = {0.2 - 0.931, 0.1, 0.708+0.004},
skillId   = SKILL_PERFORMANCE_ID,
width     = 1950,
font_size = 180,
  },
  [ROLL_SKILL_DECEPTION_ID] = {
pos = {0.2 - 0.931, 0.1, 0.76+0.004},
skillId   = SKILL_DECEPTION_ID,
width     = 1950,
font_size = 180,
  },
  [ROLL_SKILL_INTIMIDATION_ID] = {
pos = {0.2 - 0.931, 0.1, 0.813+0.004},
skillId   = SKILL_INTIMIDATION_ID,
width     = 1950,
font_size = 180,
  },
  [ROLL_SKILL_PERSUASION_ID] = {
pos = {0.2 - 0.931, 0.1, 0.863+0.004},
skillId   = SKILL_PERSUASION_ID,
width     = 1950,
font_size = 180,
  },
  -- Конец бросков
    },

    -- Кнопки бросков для оружия
    weapon_roll = {
  { pos = {-0.475, 0.1, -0.71},  index = 1 },
  { pos = {-0.475, 0.1, -0.632}, index = 2 },
  { pos = {-0.475, 0.1, -0.554}, index = 3 },
  { pos = {-0.475, 0.1, -0.476}, index = 4 },
  { pos = {-0.475, 0.1, -0.398}, index = 5 },
  { pos = {-0.475, 0.1, -0.320}, index = 6 },
  { pos = {-0.475, 0.1, -0.242}, index = 7 },
    },

    -- Счётчики хитов и монет (значение + отдельные кнопки "+"/"-" по шагам)
    resourceCounter = {
  [RESOURCE_COUNTER_HP_CURRENT_ID] = {
pos   = {0.035,0.1,-1.09},
size  = 750,
value = 0,
steps = {1, 5},
  },
  [RESOURCE_COUNTER_HP_TEMPORARY_ID] = {
pos   = {0.355,0.1,-1.425},
size  = 450,
value = 0,
steps = {1, 5},
  },
  [RESOURCE_COUNTER_HP_MAX_ID] = {
pos   = {0.045,0.1,-1.425},
size  = 450,
value = 0,
steps = {1, 5},
  },
  [RESOURCE_COUNTER_COPPER_COINS_ID] = {
pos   = {-0.35,0.1,0.04},
size  = 280,
value = 0,
steps = {1, 10, 100},
  },
  [RESOURCE_COUNTER_SILVER_COINS_ID] = {
pos   = {-0.35,0.1,0.18},
size  = 280,
value = 0,
steps = {1, 10, 100},
  },
  [RESOURCE_COUNTER_ELECTRUM_COINS_ID] = {
pos   = {-0.35,0.1,0.315},
size  = 280,
value = 0,
steps = {1, 10, 100},
  },
  [RESOURCE_COUNTER_GOLD_COINS_ID] = {
pos   = {-0.35,0.1,0.455},
size  = 280,
value = 0,
steps = {1, 10, 100},
  },
  [RESOURCE_COUNTER_PLATINUM_COINS_ID] = {
pos   = {-0.35,0.1,0.6},
size  = 280,
value = 0,
steps = {1, 10, 100},
  },
    },

    -- Служебные поля общего состояния листа
    lvl = 1,                    -- текущий подтверждённый уровень персонажа
    lvlByExp = 1,                -- уровень, вычисленный по текущему опыту (может отличаться до подтверждения)
    lvlByExpProficiency = 2,     -- бонус мастерства, соответствующий lvlByExp
    hitDiceLeft = 1,             -- оставшееся количество костей хитов
    monetWeight = 0,             -- вес монет (в фунтах)
    lockMode = 0,                -- режим блокировки: 0 - нет, 1 - частичная, 2 - полная
}

-- Параметры кнопки "Обновить уровень" в выключенном (невидимом) состоянии
local lvlUpdateBtnConditionOFF = {
    click_function = "click_none",
    color    = buttonColor,
    font_color     = buttonFontColor,
    font_size= 0,
    function_owner = self,
    height   = 0,
    label    = '',
    position = {0,0,0},
    scale    = {0,0,0},
    width    = 0,
}


--============================================================
-- Далее — исполняемый код (логика листа персонажа)
--============================================================

--============================================================
-- СОХРАНЕНИЕ
--
-- Данные сериализуются только в onSave() — непосредственно перед тем, как
-- TTS реально сохраняет объект (сейв, автосейв, попадание в контейнер,
-- дублирование и т.п.). На каждый клик ничего не считается и не пишется.
--
-- updateSave() оставлен пустым специально: по коду листа разбросаны десятки
-- вызовов updateSave() после каждого изменения (клик по чекбоксу, счётчику,
-- потеря фокуса в текстовом поле и т.д.) — чтобы не переписывать все эти
-- места, функция просто ничего не делает. Если понадобится вернуть сохранение
-- по каждому изменению — верните сюда старое тело (сериализация +
-- self.script_state = ...).
--============================================================
function updateSave()
end

-- Вызывается движком TTS непосредственно в момент реального сохранения
-- (Ctrl+S, автосохранение, попадание в контейнер, дублирование и т.п.) —
-- единственное место, где происходит сериализация состояния листа.
function onSave()
    if disableSave == true then
  return ""
    end

    return JSON.encode(ref_buttonData)
end

--============================================================
-- ИНТЕГРАЦИЯ С КНИГОЙ ЗАКЛИНАНИЙ (вызывается извне через object.call)
--
-- Книга не хранит и не дублирует правила подсчёта модификаторов/бонусов —
-- она получает уже готовые (посчитанные листом) итоговые значения и просто
-- берёт из них нужное число по имени характеристики/навыка. Единственная
-- точка правды остаётся здесь, на листе.
--============================================================

-- Возвращает всю таблицу состояния листа целиком (характеристики, навыки,
-- Считает простое арифметическое выражение вида "2+1", "8+2-1", "-3", "5".
-- Нужно для полей "Сложность спасброска" и "Бонус атаки заклинанием" —
-- их можно вписывать формулой, а не готовым числом. Возвращает число;
-- нераспознанное или пустое значение даёт 0.
function evaluateBonusFormula(str)
    if str == nil then return 0 end

    str = tostring(str)
    str = str:gsub("−", "-")   -- длинный минус (как в остальном листе) -> обычный
    str = str:gsub("%s+", "")  -- пробелы не мешают вводу вида "2 + 1"

    if str == "" then return 0 end

    -- Гарантируем знак в начале, чтобы первое число тоже поймалось паттерном ниже
    if str:sub(1, 1) ~= "+" and str:sub(1, 1) ~= "-" then
        str = "+"..str
    end

    local total = 0
    local matched = false

    for sign, number in str:gmatch("([%+%-])(%d+)") do
        matched = true
        local n = tonumber(number) or 0
        if sign == "-" then
            total = total - n
        else
            total = total + n
        end
    end

    if not matched then
        return tonumber(str) or 0
    end

    return total
end

-- спасброски, инвентарь и т.д.) — вызывается книгой заклинаний через
-- sheet.call("getButtonData"). Список конкретных ключей — в комментариях
-- к defaultButtonData выше (display_STR, display_STR_savethrow,
-- display_Athletics, display_Proficiency и т.д.)
--
-- Сложность спасброска и бонус атаки заклинанием (textbox_Spell_Save_DC,
-- textbox_Spell_Attack_Bonus) можно вписывать формулой ("2+1") — в
-- ref_buttonData.computed отдаётся уже готовое посчитанное число, книге
-- заклинаний не нужно самой парсить эту строку.
function getButtonData()
    ref_buttonData.computed = {
        spellSaveDC = evaluateBonusFormula(ref_buttonData.textbox[TEXTBOX_SPELL_SAVE_DC_ID].value),
        spellAttackBonus = evaluateBonusFormula(ref_buttonData.textbox[TEXTBOX_SPELL_ATTACK_BONUS_ID].value),
    }

    return ref_buttonData
end

--============================================================
-- СИСТЕМА БЛОКИРОВКИ ПОЛЕЙ
--
-- Включается/выключается через контекстное меню объекта (ПКМ по листу).
-- Защита двухуровневая:
--
--   1) Физическая (основная). У полей ввода в TTS интерактивна только
--      лицевая сторона — задокументировано разработчиками: "Inputs can not
--      be clicked from their back side". Поэтому при блокировке поле
--      разворачивается на 180° вокруг локальной оси Z: его кликабельная
--      сторона уходит внутрь модели листа, и курсор туда физически не
--      попадает (по нему просто нельзя щёлкнуть). Чтобы текст на обратной
--      стороне не читался зеркально, одновременно инвертируется масштаб
--      по X (buttonScale с обратным знаком) — так же, как переворачивают
--      игральную карту рубашкой вверх, но не мешая видеть номинал сквозь
--      прозрачную рубашку.
--   2) Откат значения (страховка). На случай, если поле всё же будет
--      отредактировано — через баг коллизии, вид сбоку и т.п. — click_textbox
--      при активной блокировке ничего не сохраняет и через 1 кадр
--      возвращает прежнее значение через self.editInput.
--
-- Клики по заблокированным кнопкам/чекбоксам полностью игнорируются.
--============================================================

-- Поворот текстового поля лицевой стороной внутрь модели листа (заблокировано)
local LOCK_FLIP_ROTATION = {0, 0, 180}
-- Обычный, не повёрнутый вид поля (разблокировано)
local UNLOCK_ROTATION = {0, 0, 0}

-- Подписи пунктов меню для каждого режима блокировки
local lockModeLabels = {
    [0] = "Разблокировать поля",
    [1] = "Заблокировать поля (частично)",
    [2] = "Заблокировать поля (полностью)",
}

-- Пересоздаёт контекстное меню: показывает пункты для двух режимов,
-- отличных от текущего (не циклический перебор, а прямой выбор)
function updateLockContextMenu()
    self.clearContextMenu()

    for mode = 0, 2 do
        if mode ~= ref_buttonData.lockMode then
            local targetMode = mode
            self.addContextMenuItem(lockModeLabels[targetMode], function(playerColor)
                setLockMode(targetMode)
            end)
        end
    end
end

-- Устанавливает конкретный режим блокировки (вызывается из контекстного меню)
function setLockMode(mode)
    ref_buttonData.lockMode = mode

    applyTextboxLockVisuals()
    applyCounterLockVisuals()
    applyResourceCounterLockVisuals()
    updateLockContextMenu()
    updateSave()
end

-- Проверяет, должно ли текстовое поле быть заблокировано в текущем режиме
function isTextboxLocked(textboxId)
    if ref_buttonData.lockMode == 0 then return false end
    if ref_buttonData.lockMode == 2 then return true end

    -- Для частичной блокировки (lockMode == 1) разрешаем редактировать только:
    -- КД, Кости хитов (Хиты, Временные хиты и Монеты теперь резервные
    -- счётчики resourceCounter — см. isResourceCounterLocked)
    local allowedIds = {
        [TEXTBOX_AC_ID] = true,
        [TEXTBOX_HIT_DICES_ID] = true,
    }

    return not allowedIds[textboxId]
end

-- Проверяет, должен ли чекбокс быть заблокирован в текущем режиме
function isCheckboxLocked(checkboxId)
    if ref_buttonData.lockMode == 0 then return false end
    if ref_buttonData.lockMode == 2 then return true end

    -- Для частичной блокировки (lockMode == 1) разрешаем:
    -- 6 чекбоксов испытаний от смерти
    local allowedIds = {
        [CHECKBOX_DEATH_SAVETHROW_SUCCESS_1_ID] = true,
        [CHECKBOX_DEATH_SAVETHROW_SUCCESS_2_ID] = true,
        [CHECKBOX_DEATH_SAVETHROW_SUCCESS_3_ID] = true,
        [CHECKBOX_DEATH_SAVETHROW_FAIL_1_ID] = true,
        [CHECKBOX_DEATH_SAVETHROW_FAIL_2_ID] = true,
        [CHECKBOX_DEATH_SAVETHROW_FAIL_3_ID] = true,
    }

    return not allowedIds[checkboxId]
end

-- Проверяет, должны ли кнопки управления костями хитов быть заблокированы
function isHitDiceLocked()
    -- При частичной блокировке (1) они ДОСТУПНЫ
    if ref_buttonData.lockMode == 1 then return false end
    -- В остальных случаях ориентируемся на общую логику
    return ref_buttonData.lockMode == 2
end

-- Проверяет, должны ли счётчики характеристик быть заблокированы
function isCounterLocked()
    -- При любой блокировке (1 или 2) они заблокированы
    return ref_buttonData.lockMode ~= 0
end

-- Проверяет, должны ли резервные счётчики (хиты, монеты) быть заблокированы.
-- При полной блокировке (2) заблокированы все. При частичной (1) заблокирован
-- только "Максимум хитов" — текущие/временные хиты и монеты остаются доступны
-- (как и раньше, когда это были обычные текстовые поля).
function isResourceCounterLocked(counterId)
    if ref_buttonData.lockMode == 0 then return false end
    if ref_buttonData.lockMode == 2 then return true end

    return counterId == RESOURCE_COUNTER_HP_MAX_ID
end

-- Применяет физическую защиту к текстовым полям в соответствии с lockMode
function applyTextboxLockVisuals()
    for textboxId, _ in pairs(ref_buttonData.textbox) do
        local inputIndex = inputIndexByElementIdTable[textboxId]
        if inputIndex ~= nil then
            local currentValue = ref_buttonData.textbox[textboxId].value
            if isTextboxLocked(textboxId) then
                self.editInput({
                    index    = inputIndex,
                    value    = currentValue,
                    rotation = LOCK_FLIP_ROTATION,
                    scale    = {-buttonScale[1], buttonScale[2], buttonScale[3]},
                })
            else
                self.editInput({
                    index    = inputIndex,
                    value    = currentValue,
                    rotation = UNLOCK_ROTATION,
                    scale    = buttonScale,
                })
            end
        end
    end
end

-- Показывает/скрывает кнопки шага (+/-) резервных счётчиков в зависимости
-- от блокировки. Сам дисплей со значением остаётся видимым всегда — прячутся
-- только кнопки, доступ к которым сейчас запрещён (см. isResourceCounterLocked)
function applyResourceCounterLockVisuals()
    for counterId, data in pairs(ref_buttonData.resourceCounter) do
        local scale = buttonScale
        if isResourceCounterLocked(counterId) then
            scale = {0, 0, 0}
        end

        for i, step in ipairs(data.steps) do
            local addBtnId = counterId.."_btn_add_"..step
            local subBtnId = counterId.."_btn_sub_"..step

            self.editButton({
                index = btnIndexByElementIdTable[addBtnId],
                scale = scale,
            })
            self.editButton({
                index = btnIndexByElementIdTable[subBtnId],
                scale = scale,
            })
        end
    end
end

-- Показывает/скрывает кнопки +/- счётчиков характеристик в зависимости от
-- блокировки (см. isCounterLocked). Раньше это делалось только для
-- resourceCounter — характеристики эту защиту никогда не получали.
function applyCounterLockVisuals()
    local scale = buttonScale
    if isCounterLocked() then
        scale = {0, 0, 0}
    end

    for counterId, data in pairs(ref_buttonData.counter) do
        self.editButton({
            index = btnIndexByElementIdTable[data.btnAddId],
            scale = scale,
        })
        self.editButton({
            index = btnIndexByElementIdTable[data.btnSubId],
            scale = scale,
        })
    end
end

--Процедура инициализации листа при загрузке
function onload(saved_data)
    if disableSave == true then
  saved_data = ""
    end

    if saved_data ~= "" then
  local loaded_data = JSON.decode(saved_data)
  ref_buttonData = loaded_data
    else
  ref_buttonData = defaultButtonData
    end

    -- Поддержка старых сохранений, созданных до появления системы блокировки
    if ref_buttonData.lockMode == nil then
        if ref_buttonData.locked == true then
            ref_buttonData.lockMode = 2
        else
            ref_buttonData.lockMode = 0
        end
        ref_buttonData.locked = nil
    end
    if ref_buttonData.weapon_roll == nil then
  ref_buttonData.weapon_roll = defaultButtonData.weapon_roll
    end
    if ref_buttonData.select == nil then
  ref_buttonData.select = defaultButtonData.select
    end
    if ref_buttonData.resourceCounter == nil then
  ref_buttonData.resourceCounter = defaultButtonData.resourceCounter
    end

    spawnedButtonCount = 0

    createCheckbox()
    createCounter()
    createResourceCounter()
    createDisplay()
    createRolls()
    createWeaponRolls()
    createTextbox()
    createSelect()
    createLvlUpdateBtn()
    createHitDiceCounters()

    updateJumpAndWeight()
    updateMonetWeight()

    lvlRefresh()
    applyTextboxLockVisuals()
    applyCounterLockVisuals()
    applyResourceCounterLockVisuals()
    updateLockContextMenu()
end

--Функции-обработчики кликов по кнопкам

-- Открывает диалог выбора заклинательной характеристики
function onClickSelect(selectId, playerColor)
    local data = ref_buttonData.select[selectId]

    local currentIndex = 1
    for i, paramId in ipairs(spellAbilityOptions) do
  if paramId == data.value then
currentIndex = i
break
  end
    end

    local optionLabels = {}
    for i, paramId in ipairs(spellAbilityOptions) do
  optionLabels[i] = spellAbilityLabels[paramId]
    end

    Player[playerColor].showOptionsDialog(
  "Заклинательная характеристика",
  optionLabels,
  currentIndex,
  function(selectedText, selectedIndex, callbackPlayerColor)
onSelectSpellAbility(selectId, selectedIndex)
  end
    )
end

-- Применяет выбор из диалога и обновляет подпись кнопки
function onSelectSpellAbility(selectId, selectedIndex)
    local paramId = spellAbilityOptions[selectedIndex]
    if paramId == nil then return end

    ref_buttonData.select[selectId].value = paramId

    self.editButton({
  index = btnIndexByElementIdTable[selectId],
  label = spellAbilityLabels[paramId],
    })

    updateSave()
end

-- Отмечает/снимает отметку с чекбокса
-- isRightClick == true, если чекбокс кликнули правой кнопкой мыши
function click_checkbox(checkboxId, isRightClick)
    -- Если поля заблокированы — игнорируем клик, состояние не меняется
    if isCheckboxLocked(checkboxId) then
        return
    end

    local checkbox = ref_buttonData.checkbox[checkboxId]
    local skillId = checkbox.skillId
    local atributo

    if not (skillId == nil) then
  local paramId = paramIdBySkillId[skillId]

  atributo = ref_buttonData.display["display_"..paramId].value
    end

    -- ПКМ по уже отмеченному навыку (не спасброску) — переключает
    -- Компетентность (двойной бонус мастерства), не трогая саму отметку
    if isRightClick == true then
  if skillId == nil or isSkillSavethrow(skillId) or checkbox.state ~= true then
      return
  end

  checkbox.expertise = not (checkbox.expertise == true)

  local proficiency = tonumber(ref_buttonData.display[DISPLAY_PROFICIENCY_ID].value) or 0
  local bonus = tonumber(ref_buttonData.textbox["textbox_"..skillId].value) or 0
  local newValue = atributo + bonus + proficiency * getProficiencyMultiplier(checkbox)

  ref_buttonData.display["display_"..skillId].value = newValue
  self.editButton({index = btnIndexByElementIdTable["display_"..skillId], label = newValue})

  local checkboxLabel = CHECKBOX_CHAR_FULL
  if checkbox.expertise == true then
      checkboxLabel = CHECKBOX_CHAR_EXPERTISE
  end
  self.editButton({index = btnIndexByElementIdTable[checkboxId], label = checkboxLabel})

  if checkboxId == "checkbox_"..SKILL_PERCEPTION_ID then
      ref_buttonData.display[DISPLAY_PASSIVE_PERCEPTION_ID].value = 10 + newValue
      self.editButton({
    index = btnIndexByElementIdTable[DISPLAY_PASSIVE_PERCEPTION_ID],
    label = ref_buttonData.display[DISPLAY_PASSIVE_PERCEPTION_ID].value,
      })
  end

  updateSave()
  return
    end

    -- Пересчёт итогового значения навыка с учётом отметки мастерства
    if checkbox.state == false then
  checkbox.state = true

  if not (skillId == nil) then
local proficiency = tonumber(ref_buttonData.display[DISPLAY_PROFICIENCY_ID].value) or 0
local bonus = tonumber(ref_buttonData.textbox["textbox_"..skillId].value) or 0
local newValue = atributo + bonus + proficiency * getProficiencyMultiplier(checkbox)
ref_buttonData.display["display_"..skillId].value = newValue
self.editButton({index = btnIndexByElementIdTable["display_"..skillId], label = newValue})
  end

  self.editButton({index = btnIndexByElementIdTable[checkboxId], label = CHECKBOX_CHAR_FULL})
  -- Пересчёт итогового значения навыка при снятии отметки
    else
  checkbox.state = false
  -- Компетентность имеет смысл только для отмеченного навыка — снимаем вместе с отметкой
  checkbox.expertise = false

  if not (skillId == nil) then
local bonus = ref_buttonData.textbox["textbox_"..skillId].value
bonus = tonumber(bonus) or 0
local newVal = atributo + bonus

ref_buttonData.display["display_"..skillId].value = newVal
self.editButton({index = btnIndexByElementIdTable["display_"..skillId], label = newVal})
  end

  self.editButton({index = btnIndexByElementIdTable[checkboxId], label = CHECKBOX_CHAR_EMPTY})
    end

    -- Обновление пассивной внимательности при изменении чекбокса навыка "Внимательность"
    if checkboxId == "checkbox_"..SKILL_PERCEPTION_ID then
  local proficiency = tonumber(ref_buttonData.display[DISPLAY_PROFICIENCY_ID].value) or 0
  local bonus = tonumber(ref_buttonData.textbox[TEXTBOX_SKILL_PERCEPTION_ID].value) or 0

  ref_buttonData.display[DISPLAY_PASSIVE_PERCEPTION_ID].value = 10 + atributo + bonus + proficiency * getProficiencyMultiplier(checkbox)

  self.editButton({
index = btnIndexByElementIdTable[DISPLAY_PASSIVE_PERCEPTION_ID],
label = ref_buttonData.display[DISPLAY_PASSIVE_PERCEPTION_ID].value,
  })
    end

    updateJumpAndWeight()
    updateSave()
end

-- Изменяет значение счётчика характеристики на amount и пересчитывает всё зависимое
-- (модификатор характеристики, связанные навыки, пассивную внимательность)
function click_counter(amount, counterId)
    -- Если поля заблокированы — игнорируем клик, состояние не меняется
    if isCounterLocked() then
        return
    end

    local paramId = ref_buttonData.counter[counterId].paramId

    ref_buttonData.counter[counterId].value = ref_buttonData.counter[counterId].value + amount
    ref_buttonData.display["display_"..paramId].value = math.floor((ref_buttonData.counter[counterId].value - 10) / 2)

    -- Обновляем значение характеристики
    self.editButton({
  index = btnIndexByElementIdTable["counter_"..paramId],
  label = ref_buttonData.counter[counterId].value,
    })

    -- Обновляем модификатор характеристики
    self.editButton({
  index = btnIndexByElementIdTable["display_"..paramId],
  label = ref_buttonData.display["display_"..paramId].value,
    })

    -- Объявляем переменные модификатора характеристики и бонуса мастерства
    local atributo = ref_buttonData.display["display_"..paramId].value

    local proficiency = ref_buttonData.display[DISPLAY_PROFICIENCY_ID].value

    proficiency = tonumber(proficiency) or 0

    -- Пересчитываем и обновляем все навыки, связанные с этой характеристикой

    for i, skillId in ipairs(skillIdListByParamId[paramId]) do
  -- Дополнительный бонус навыка из текстового поля
  local bonus = ref_buttonData.textbox["textbox_"..skillId].value
  bonus = tonumber(bonus) or 0

  -- Обновление навыка с учётом мастерства и без него
  if ref_buttonData.checkbox["checkbox_"..skillId].state == true then
ref_buttonData.display["display_"..skillId].value = atributo + bonus + proficiency
self.editButton({index = btnIndexByElementIdTable["display_"..skillId], label = atributo + bonus + proficiency})
  else
ref_buttonData.display["display_"..skillId].value = atributo + bonus
self.editButton({index = btnIndexByElementIdTable["display_"..skillId], label = atributo + bonus})
  end

  -- Обновление пассивной внимательности
  if skillId == SKILL_PERCEPTION_ID then
-- С учётом мастерства во "Внимательности" или без него
if ref_buttonData.checkbox["checkbox_"..SKILL_PERCEPTION_ID].state == true then
    ref_buttonData.display[DISPLAY_PASSIVE_PERCEPTION_ID].value = 10 + atributo + bonus + proficiency
    self.editButton({
  index = btnIndexByElementIdTable[DISPLAY_PASSIVE_PERCEPTION_ID],
  label = ref_buttonData.display[DISPLAY_PASSIVE_PERCEPTION_ID].value,
    })
else
    ref_buttonData.display[DISPLAY_PASSIVE_PERCEPTION_ID].value = 10 + atributo + bonus
    self.editButton({
  index = btnIndexByElementIdTable[DISPLAY_PASSIVE_PERCEPTION_ID],
  label = ref_buttonData.display[DISPLAY_PASSIVE_PERCEPTION_ID].value,
    })
end
  end
    end

    updateJumpAndWeight()

    -- Сохраняем обновлённое состояние
    updateSave()
end

-- Список счётчиков-монет (для проверки в click_resource_counter)
local moneyCounterIds = {
    [RESOURCE_COUNTER_COPPER_COINS_ID] = true,
    [RESOURCE_COUNTER_SILVER_COINS_ID] = true,
    [RESOURCE_COUNTER_ELECTRUM_COINS_ID] = true,
    [RESOURCE_COUNTER_GOLD_COINS_ID] = true,
    [RESOURCE_COUNTER_PLATINUM_COINS_ID] = true,
}

-- Обрабатывает клик по кнопке шага резервного счётчика (хиты, монеты).
-- amount уже содержит нужный знак (+N для кнопки в правом столбике,
-- −N для кнопки в левом столбике — см. createResourceCounter)
function click_resource_counter(amount, counterId)
    if isResourceCounterLocked(counterId) then
        return
    end

    local data = ref_buttonData.resourceCounter[counterId]
    data.value = data.value + amount
    if data.value < 0 then
  data.value = 0
    end

    self.editButton({
  index = btnIndexByElementIdTable[counterId],
  label = data.value,
    })

    -- Изменилось количество монет — пересчитываем их вес
    if moneyCounterIds[counterId] == true then
  updateMonetWeight()
    end

    updateSave()
end

-- Применяет введённое значение к текстовому полю
-- selected == false означает, что игрок закончил ввод (поле потеряло фокус)
function click_textbox(value, selected, textboxId)
    -- Страховка на случай блокировки: основная защита — физический разворот
    -- поля (см. applyTextboxLockVisuals), но если редактирование всё же
    -- произошло, ничего не сохраняем и через 1 кадр возвращаем прежний текст.
    if isTextboxLocked(textboxId) then
  if selected == false then
Wait.frames(
    function()
self.editInput({
    index = inputIndexByElementIdTable[textboxId],
    value = ref_buttonData.textbox[textboxId].value,
})
    end,
    1
)
  end
  return
    end

    if selected == false then
  ref_buttonData.textbox[textboxId].value = value

  -- Пересчёт значений с учётом бонуса мастерства
  updateSkillsByProficiency()

  -- Изменился рост — обновляем высоту прыжка с руками
  if textboxId == TEXTBOX_HEIGHT_ID then
updateJumpAndWeight()
  end

  -- Изменился опыт — обновляем уровень
  if textboxId == TEXTBOX_XP_ID then
updateLevelByExp()
  end

  updateSave()
    end
end

-- Пересчитывает суммарный вес монет и обновляет соответствующий дисплей.
-- Монеты теперь резервные счётчики (resourceCounter), а не текстовые поля.
function updateMonetWeight()
    local coinCounterIdList = {
  RESOURCE_COUNTER_COPPER_COINS_ID,
  RESOURCE_COUNTER_SILVER_COINS_ID,
  RESOURCE_COUNTER_ELECTRUM_COINS_ID,
  RESOURCE_COUNTER_GOLD_COINS_ID,
  RESOURCE_COUNTER_PLATINUM_COINS_ID,
    }

    local singleCoinWeight = 0.02

    local coinTotalCount = 0
    for i, coinCounterId in ipairs(coinCounterIdList) do
  local coinCount = ref_buttonData.resourceCounter[coinCounterId].value
  if not (coinCount == nil or coinCount == "") then
coinTotalCount = coinTotalCount + tonumber(coinCount)
  end
    end

    local coinTotalWeight = math.ceil(singleCoinWeight * coinTotalCount)
    local kgTotalWeight = math.ceil(coinTotalWeight * POUND_PER_KG)
    local poundText = declensionRus(coinTotalWeight, 'фунт', 'фунта', 'фунтов')
    local text = "Вес монет: "..coinTotalWeight.." "..poundText.." ("..kgTotalWeight.." кг)"
    if coinTotalWeight == 0 then
  text = NET_MONET_TEXT
    end

    ref_buttonData.monetWeight = coinTotalWeight
    checkOvercumbrance()

    ref_buttonData.display[DISPLAY_MONET_WEIGHT_ID].value = text
    self.editButton({
  index = btnIndexByElementIdTable[DISPLAY_MONET_WEIGHT_ID],
  label = text,
  value = text,
    })
end

-- Подсвечивает красным дисплеи грузоподъёмности, если вес монет превышает лимит (перегруз)
function checkOvercumbrance()
    local redBtnParams = {
  color = { 1, 0, 0 },
  font_color = { 1, 1, 1 },
  width = 1500,
  height = 500,
  tooltip = 'Перегруз',
    }
    local normalBtnParams = {
  color = buttonColor,
  font_color = buttonFontColor,
  width = 0,
  height = 0,
  tooltip = nil,
    }

    local weightLimits = {
  DISPLAY_WEIGHT_CAPACITY_ID,
  DISPLAY_RAISE_LIFT_AND_PULL_ID,
    }
    for i, weightLimitDisplayId in ipairs(weightLimits) do
  if ref_buttonData.monetWeight > ref_buttonData.display[weightLimitDisplayId].value then
local params = redBtnParams
params.index = btnIndexByElementIdTable[weightLimitDisplayId]
self.editButton(params)
  else
local params = normalBtnParams
params.index = btnIndexByElementIdTable[weightLimitDisplayId]
self.editButton(params)
  end
    end
end

-- Возвращает правильную форму слова в зависимости от числа (склонение на русском)
function declensionRus(num, singleText, doubleText, multipleText)
    local numPart = math.fmod(math.abs(num), 100)

    if numPart > 9 and numPart < 20 then
  return multipleText
    else
  local shortPart = math.fmod(numPart, 10)

  if shortPart == 1 then
return singleText
  end
  if shortPart > 1 and shortPart < 5 then
return doubleText
  else
return multipleText
  end
    end
end

-- Заглушка для кнопок с фоновой подложкой (без действия по клику)
function click_none() end

-- Пересчитывает все навыки с учётом текущего бонуса мастерства (например, после смены уровня)
function updateSkillsByProficiency()
    -- Текущий бонус мастерства
    local proficiency = ref_buttonData.display[DISPLAY_PROFICIENCY_ID].value
    proficiency = tonumber(proficiency) or 0

    -- Пересчёт значений навыков при изменении бонуса мастерства
    for skillId, paramId in pairs(paramIdBySkillId) do
  local atributo = ref_buttonData.display["display_"..paramId].value

  local bonus = ref_buttonData.textbox["textbox_"..skillId].value
  bonus = tonumber(bonus) or 0

  -- Мастерство (обычное или удвоенное при Компетентности) прибавляется
  -- только если навык отмечен как освоенный
  local checkbox = ref_buttonData.checkbox["checkbox_"..skillId]
  local nextValue = atributo + bonus + proficiency * getProficiencyMultiplier(checkbox)

  ref_buttonData.display["display_"..skillId].value = nextValue
  self.editButton({
index = btnIndexByElementIdTable["display_"..skillId],
label = nextValue,
  })

  -- Обновление пассивной внимательности с учётом мастерства
  if skillId == SKILL_PERCEPTION_ID then
ref_buttonData.display[DISPLAY_PASSIVE_PERCEPTION_ID].value = 10 + nextValue
self.editButton({
    index = btnIndexByElementIdTable[DISPLAY_PASSIVE_PERCEPTION_ID],
    label = ref_buttonData.display[DISPLAY_PASSIVE_PERCEPTION_ID].value,
})
  end
    end
end

--============================================================
-- Создание кнопок и элементов интерфейса
--============================================================

-- Пересчитывает грузоподъёмность и характеристики прыжка (зависят от Силы и роста)
function updateJumpAndWeight()
    local weightCapacityKoef = 1
    if ref_buttonData.checkbox[CHECKBOX_WEIGHT_CAPACITY_X_2].state == true then
  weightCapacityKoef = 2
    end

    -- Обновляем грузоподъёмность
    local weightCapacity = ref_buttonData.counter[COUNTER_PARAM_STR_ID].value * 15 * weightCapacityKoef
    ref_buttonData.display[DISPLAY_WEIGHT_CAPACITY_ID].value = weightCapacity
    self.editButton({
  index = btnIndexByElementIdTable[DISPLAY_WEIGHT_CAPACITY_ID],
  label = weightCapacity,
    })

    -- Обновляем "поднять/толкнуть/потащить"
    local raiseLiftPullCapacity = weightCapacity * 2
    ref_buttonData.display[DISPLAY_RAISE_LIFT_AND_PULL_ID].value = raiseLiftPullCapacity
    self.editButton({
  index = btnIndexByElementIdTable[DISPLAY_RAISE_LIFT_AND_PULL_ID],
  label = raiseLiftPullCapacity,
    })

    -- Обновляем высоту прыжка
    local jumpHeight = ref_buttonData.display[DISPLAY_PARAM_STR_ID].value + 3
    ref_buttonData.display[DISPLAY_JUMP_HEIGHT_ID].value = jumpHeight
    self.editButton({
  index = btnIndexByElementIdTable[DISPLAY_JUMP_HEIGHT_ID],
  label = jumpHeight,
    })

    -- Обновляем дальность прыжка
    local jumpDistance = ref_buttonData.counter[COUNTER_PARAM_STR_ID].value
    ref_buttonData.display[DISPLAY_JUMP_DISTANCE_ID].value = jumpDistance
    self.editButton({
  index = btnIndexByElementIdTable[DISPLAY_JUMP_DISTANCE_ID],
  label = jumpDistance,
    })

    -- Обновляем высоту прыжка с касанием руками (зависит от роста)
    local characterHeight = ref_buttonData.textbox[TEXTBOX_HEIGHT_ID].value
    characterHeight = tonumber(characterHeight) or 0

    local characterOneAndHalfHeight = math.floor(characterHeight * 1.5)
    local jumpHeightWithHands = jumpHeight + characterOneAndHalfHeight
    ref_buttonData.display[DISPLAY_JUMP_HEIGHT_WITH_HANDS_ID].value = jumpHeightWithHands
    self.editButton({
  index = btnIndexByElementIdTable[DISPLAY_JUMP_HEIGHT_WITH_HANDS_ID],
  label = jumpHeightWithHands,
    })

    -- Обновляем высоту прыжка без разбега
    local jumpHeightNoRunning = math.floor(jumpHeight / 2)
    ref_buttonData.display[DISPLAY_JUMP_HEIGHT_NO_RUNNING_ID].value = jumpHeightNoRunning
    self.editButton({
  index = btnIndexByElementIdTable[DISPLAY_JUMP_HEIGHT_NO_RUNNING_ID],
  label = jumpHeightNoRunning,
    })

    -- Обновляем дальность прыжка без разбега
    local jumpDistanceNoRunning = math.floor(jumpDistance / 2)
    ref_buttonData.display[DISPLAY_JUMP_DISTANCE_NO_RUNNING_ID].value = jumpDistanceNoRunning
    self.editButton({
  index = btnIndexByElementIdTable[DISPLAY_JUMP_DISTANCE_NO_RUNNING_ID],
  label = jumpDistanceNoRunning,
    })

    -- Обновляем высоту прыжка с руками без разбега
    local jumpHeightWithHandsNoRunning = jumpHeightNoRunning + characterOneAndHalfHeight
    ref_buttonData.display[DISPLAY_JUMP_HEIGHT_WITH_HANDS_NO_RUNNING_ID].value = jumpHeightWithHandsNoRunning
    self.editButton({
  index = btnIndexByElementIdTable[DISPLAY_JUMP_HEIGHT_WITH_HANDS_NO_RUNNING_ID],
  label = jumpHeightWithHandsNoRunning,
    })

    checkOvercumbrance()
end

-- Кнопка "Обновить уровень" - включение/выключение видимости
function setLvlUpdateBtnCondition(doActivate)
    if doActivate then
  self.editButton({
click_function = "onClickLvlUpdateBtn",
color    = buttonColor,
font_color     = buttonFontColor,
font_size= 350,
function_owner = self,
height   = 500,
index    = btnIndexByElementIdTable.lvlUpdateBtn,
label    = 'Обновить уровень ('..ref_buttonData.lvlByExp..')',
position = {1.040,0.1,-1.655},
scale    = buttonScale,
width    = 4000,
  })
    else
  lvlUpdateBtnConditionOFF.index = btnIndexByElementIdTable.lvlUpdateBtn
  self.editButton(lvlUpdateBtnConditionOFF)
    end
end

-- Кнопка "Обновить уровень" - создание
function createLvlUpdateBtn()
    createBtnAndSaveIndex("lvlUpdateBtn", lvlUpdateBtnConditionOFF)
end

-- Полный пересчёт уровня (при загрузке листа)
function lvlRefresh()
    updateLevelByExp()
    onClickLvlUpdateBtn()
end

-- Кнопка "Обновить уровень" - клик (подтверждает новый уровень персонажа)
function onClickLvlUpdateBtn()
    ref_buttonData.lvl = ref_buttonData.lvlByExp

    -- ВАЖНО: сохраняем значение не только визуально (editButton), но и в
    -- ref_buttonData.display — иначе при пересборке интерфейса (переключение
    -- блокировки листа, перезагрузка партии) createDisplay() возьмёт из
    -- ref_buttonData старое/дефолтное значение, и уровень визуально "слетит",
    -- хотя ref_buttonData.lvl при этом останется правильным.
    ref_buttonData.display[DISPLAY_LEVEL_ID].value = ref_buttonData.lvlByExp
    self.editButton({
  index = btnIndexByElementIdTable[DISPLAY_LEVEL_ID],
  label = ref_buttonData.lvlByExp,
  value = ref_buttonData.lvlByExp,
    })

    ref_buttonData.display[DISPLAY_NEXT_LVL_ID].value = ref_buttonData.nextLvlExp
    self.editButton({
  index = btnIndexByElementIdTable[DISPLAY_NEXT_LVL_ID],
  label = ref_buttonData.nextLvlExp,
  value = ref_buttonData.nextLvlExp,
    })

    -- Храним уже отформатированную строку ("+N"), как и в defaultButtonData —
    -- именно она уходит в label при пересборке. На вычисления это не влияет:
    -- Lua автоматически приводит "+3" к числу 3 в арифметике и через tonumber.
    ref_buttonData.display[DISPLAY_PROFICIENCY_ID].value = '+'..ref_buttonData.lvlByExpProficiency

    self.editButton({
  index = btnIndexByElementIdTable[DISPLAY_PROFICIENCY_ID],
  label = ref_buttonData.display[DISPLAY_PROFICIENCY_ID].value,
  value = ref_buttonData.display[DISPLAY_PROFICIENCY_ID].value,
    })

    updateSkillsByProficiency()
    setLvlUpdateBtnCondition(false)
    updateHitDiceText()
    updateSave()
end

-- Пересчитывает уровень по значению опыта в поле XP
function updateLevelByExp()
    local exp = tonumber(ref_buttonData.textbox[TEXTBOX_XP_ID].value) or EXP_MIN

    -- Исправляем значение опыта, если оно вышло за допустимые границы
    if (exp < EXP_MIN or exp > EXP_MAX) then
  if (exp < EXP_MIN) then exp = EXP_MIN end
  if (exp > EXP_MAX) then exp = EXP_MAX end

  -- Исправляем значение опыта в самом текстовом поле
  ref_buttonData.textbox[TEXTBOX_XP_ID].value = exp
  Wait.time(
function ()
    self.editInput({
  index = inputIndexByElementIdTable[TEXTBOX_XP_ID],
  value = exp,
    })
end,
0
  )
    end

    for i, data in ipairs(LVL_BY_EXP) do
  if ((data.min <= exp) and (exp <= data.max)) then
ref_buttonData.lvlByExp = data.lvl
ref_buttonData.lvlByExpProficiency = data.proficiency

if (i == #LVL_BY_EXP) then
    ref_buttonData.nextLvlExp = '/ —'
else
    ref_buttonData.nextLvlExp = '/ '..(data.max + 1)
end

if (ref_buttonData.lvlByExp ~= ref_buttonData.lvl) then
    setLvlUpdateBtnCondition(true)
end
  end
    end
end

-- Создаёт кнопки + и - для костей хитов
function createHitDiceCounters()
    local size = 350

    -- Кнопка броска одной кости хитов (над полями +/- и счётчиком)
    createBtnAndSaveIndex(
  "hitDiceRoll",
  {
click_function = "onClickRollHitDice",
color    = buttonColor,
font_color     = buttonFontColor,
font_size= size * 0.35,
function_owner = self,
height   = size,
label    = 'Бросить кость хитов',
position = {0.85,0.1,-1.29},
scale    = buttonScale,
width    = size * 3.6,
  }
    )

    createBtnAndSaveIndex(
  "hitDiceIncrement",
  {
click_function = "hitDiceIncrement",
color    = buttonColor,
font_color     = buttonFontColor,
font_size= size,
function_owner = self,
height   = size,
label    = '+',
position = {0.68,0.1,-1.47},
scale    = buttonScale,
width    = size,
  }
    )
    createBtnAndSaveIndex(
  "hitDiceDecrement",
  {
click_function = "hitDiceDecrement",
color    = buttonColor,
font_color     = buttonFontColor,
font_size= size,
function_owner = self,
height   = size,
label    = '-',
position = {0.68,0.1,-1.29},
scale    = buttonScale,
width    = size,
  }
    )

    updateHitDiceText()
end

-- Увеличить количество оставшихся костей хитов
function hitDiceIncrement()
    -- Если поля заблокированы — игнорируем клик
    if isHitDiceLocked() then
        return
    end
    changeHitDiceLeft(true)
end

-- Уменьшить количество оставшихся костей хитов
function hitDiceDecrement()
    -- Если поля заблокированы — игнорируем клик
    if isHitDiceLocked() then
        return
    end
    changeHitDiceLeft(false)
end

-- Бросает одну кость хитов (физически), тратит её из оставшихся и
-- восстанавливает текущие хиты на выпавшее значение, но не выше максимума.
-- Кость хитов тратится СРАЗУ в момент клика (синхронно), а не после того,
-- как кубик долетит и остановится — так можно кидать несколько кубиков
-- одновременно (кнопка ничем не блокируется), но нельзя кинуть больше
-- костей, чем их реально осталось: следующий клик уже видит уменьшённое
-- значение, даже если предыдущий кубик ещё летит.
function onClickRollHitDice(obj, playerColor)
    if isHitDiceLocked() then
        return
    end

    local hitDiceLeft = tonumber(ref_buttonData.hitDiceLeft) or 0
    if hitDiceLeft <= 0 then
        -- Нет доступных костей хитов — бросать нечего
        return
    end

    -- Размер кости хитов игрок указывает в соседнем текстовом поле (например "8" для к8)
    local diceSize = tonumber(ref_buttonData.textbox[TEXTBOX_HIT_DICES_ID].value) or 8

    -- Тратим кость хитов сразу, а не в колбэке (см. пояснение выше)
    changeHitDiceLeft(false)

    rollPhysicalDiceGroups(
  {{name = "hitDice", diceType = diceSize, diceCount = 1}},
  function(results)
      local roll = results.hitDice.total
      local conModifier = tonumber(ref_buttonData.display[DISPLAY_PARAM_CON_ID].value) or 0

      local healed = roll + conModifier
      -- Кость хитов лечит минимум на 1, даже если модификатор Телосложения отрицательный
      if healed < 1 then
    healed = 1
      end

      -- Восстанавливаем текущие хиты, но не выше максимума
      local currentHp = tonumber(ref_buttonData.resourceCounter[RESOURCE_COUNTER_HP_CURRENT_ID].value) or 0
      local maxHp = tonumber(ref_buttonData.resourceCounter[RESOURCE_COUNTER_HP_MAX_ID].value) or 0

      local newHp = currentHp + healed
      if newHp > maxHp then
    newHp = maxHp
      end

      ref_buttonData.resourceCounter[RESOURCE_COUNTER_HP_CURRENT_ID].value = newHp
      self.editButton({
    index = btnIndexByElementIdTable[RESOURCE_COUNTER_HP_CURRENT_ID],
    label = newHp,
      })

      -- Сообщение в чат, как и для остальных бросков
      local steam_name = Player[playerColor].steam_name
      local charSheetName = self.getName()
      if charSheetName == nil or charSheetName == "" then
    charSheetName = "Лист персонажа"
      end
      local playerColorRBB = convertColorNameIntoRgbString(playerColor)
      local charSheetColor = colorToHex(self.getColorTint())

      local modifierSign = '+'
      if conModifier < 0 then
    modifierSign = '−'
      end
      local modifierText = ' '..modifierSign..' '..math.abs(conModifier)

      broadcastToAll(
    '['..playerColorRBB..']'..steam_name..'[-]: '
    ..'Кость хитов (к'..diceSize..') для ['..charSheetColor..'][i]'..charSheetName..'[/i][-]: '
    ..roll..modifierText..' = [b]'..healed..'[/b] ('..newHp..' хитов)'
      )
  end
    )
end

-- Изменяет количество оставшихся костей хитов в пределах [0, уровень персонажа]
function changeHitDiceLeft(addDice)
    local HIT_DICE_MIN = 0
    local HIT_DICE_MAX = ref_buttonData.lvl

    local hitDiceLeft = tonumber(ref_buttonData.hitDiceLeft) or HIT_DICE_MIN

    local nextHitDiceLeft = (addDice == true) and (hitDiceLeft + 1) or (hitDiceLeft - 1)

    -- Не даём значению выйти за допустимые границы
    if (nextHitDiceLeft < HIT_DICE_MIN or nextHitDiceLeft > HIT_DICE_MAX) then
  if (nextHitDiceLeft < HIT_DICE_MIN) then nextHitDiceLeft = HIT_DICE_MIN end
  if (nextHitDiceLeft > HIT_DICE_MAX) then nextHitDiceLeft = HIT_DICE_MAX end
    end

    ref_buttonData.hitDiceLeft = nextHitDiceLeft
    updateHitDiceText()
end

-- Обновляет текст "осталось костей хитов / всего"
function updateHitDiceText()
    local hitDiceLeft = tonumber(ref_buttonData.hitDiceLeft)
    local hitDiceText = hitDiceLeft..'/'..ref_buttonData.lvl..'к'

    ref_buttonData.display[DISPLAY_HIT_DICES_LEFT_ID].value = hitDiceText
    self.editButton({
  index = btnIndexByElementIdTable[DISPLAY_HIT_DICES_LEFT_ID],
  label = hitDiceText,
  value = hitDiceText,
    })
end

-- Создаёт все кнопки-чекбоксы
function createCheckbox()
    for checkboxId, data in pairs(ref_buttonData.checkbox) do
  -- Функция-обработчик клика для конкретного чекбокса
  local funcName = "checkbox"..checkboxId
  local func = function(obj, playerColor, isRightClick)
click_checkbox(checkboxId, isRightClick)
  end

  self.setVar(funcName, func)

  -- Подпись в зависимости от текущего состояния (пусто / отмечен / Компетентность)
  local label = CHECKBOX_CHAR_EMPTY
  if data.state == true then
label = CHECKBOX_CHAR_FULL
if data.expertise == true then
    label = CHECKBOX_CHAR_EXPERTISE
end
  end

  -- Создаём кнопку и сохраняем её индекс
  createBtnAndSaveIndex(
checkboxId,
{
    click_function = funcName,
    color    = buttonColor,
    font_color     = buttonFontColor,
    font_size= data.size,
    function_owner = self,
    height   = data.size,
    label    = label,
    position = data.pos,
    scale    = buttonScale,
    width    = data.size,
}
  )

  spawnedButtonCount = spawnedButtonCount + 1
    end
end

-- Создаёт счётчики характеристик вместе с кнопками + и -
function createCounter()
    for counterId, data in pairs(ref_buttonData.counter) do
  --Sets up display
  local displayNumber = spawnedButtonCount
  --Sets up label
  local label = data.value
  --Sets height/width for display
  local size = data.size
  if data.hideBG == true then
size = 0
  end

  --Creates button and counts it
  createBtnAndSaveIndex(
counterId,
{
    click_function = "click_none",
    color    = buttonColor,
    font_color     = buttonFontColor,
    font_size= data.size,
    function_owner = self,
    height   = size,
    label    = label,
    position = data.pos,
    scale    = buttonScale,
    width    = size,
}
  )

  spawnedButtonCount = spawnedButtonCount + 1

  -- Кнопка "+1"
  local funcName = data.btnAddId
  local func = function()
click_counter(1, counterId)
  end

  self.setVar(funcName, func)
  -- Смещение кнопок +/- относительно центра счётчика
  local offsetDistance = (data.size / 2 + data.size / 4) * (buttonScale[1] * 0.002)
  local pos = {
data.pos[1] + offsetDistance,
data.pos[2],
data.pos[3],
  }
  -- Размер кнопок +/- (вдвое меньше самого счётчика)
  local size = data.size / 2

  -- Создаём кнопку и сохраняем её индекс
  createBtnAndSaveIndex(
data.btnAddId,
{
    click_function = funcName,
    color    = buttonColor,
    font_color     = buttonFontColor,
    font_size= size,
    function_owner = self,
    height   = size,
    label    = "+",
    position = pos,
    scale    = buttonScale,
    width    = size,
}
  )

  spawnedButtonCount = spawnedButtonCount + 1

  -- Кнопка "-1"
  local funcName = data.btnSubId
  local func = function()
click_counter(-1, counterId)
  end

  self.setVar(funcName, func)

  -- Позиция кнопки "-1"
  local pos = {
data.pos[1] - offsetDistance,
data.pos[2],
data.pos[3],
  }

  -- Создаём кнопку и сохраняем её индекс
  createBtnAndSaveIndex(
data.btnSubId,
{
    click_function = funcName,
    color    = buttonColor,
    font_color     = buttonFontColor,
    font_size= size,
    function_owner = self,
    height   = size,
    label    = "−",
    position = pos,
    scale    = buttonScale,
    width    = size,
}
  )

  spawnedButtonCount = spawnedButtonCount + 1
    end
end

-- Создаёт резервные счётчики (хиты, монеты): кнопка-дисплей со значением,
-- столбик кнопок "+шаг" справа и столбик кнопок "-шаг" слева (шаги — из
-- data.steps, например {1,5,10}). Кнопки скрываются (масштаб 0), когда
-- счётчик заблокирован — см. applyResourceCounterLockVisuals.
function createResourceCounter()
    for counterId, data in pairs(ref_buttonData.resourceCounter) do
  -- Кнопка-дисплей с текущим значением (сама не кликабельна)
  createBtnAndSaveIndex(
counterId,
{
    click_function = "click_none",
    color    = buttonColor,
    font_color     = buttonFontColor,
    font_size= data.size,
    function_owner = self,
    height   = data.size,
    label    = data.value,
    position = data.pos,
    scale    = buttonScale,
    width    = data.size * 2,
}
  )

  spawnedButtonCount = spawnedButtonCount + 1

  -- Кнопки шага: "+" столбиком справа от значения, "-" столбиком слева
  -- (позиции примерные, подгоните вручную под физический лист)
  local btnSize = data.size / 2
  local columnOffsetX = (data.size / 2 + btnSize) * (buttonScale[1] * 0.0025)
  local rowSpacingZ = (btnSize + btnSize / 4) * (buttonScale[3] * 0.00185)

  for i, step in ipairs(data.steps) do
local rowZ = data.pos[3] + rowSpacingZ * (i - 2)
-- Группа с шагами {1,5} (хиты) — опускаем чуть ниже, монеты ({1,10,100}) не трогаем
if #data.steps == 2 then
    rowZ = rowZ + 0.043
end

-- Кнопка "+step" (столбик справа)
local addBtnId = counterId.."_btn_add_"..step
local addFunc = function()
    click_resource_counter(step, counterId)
end
self.setVar(addBtnId, addFunc)

createBtnAndSaveIndex(
    addBtnId,
    {
click_function = addBtnId,
color    = buttonColor,
font_color     = buttonFontColor,
font_size= btnSize * 0.7,
function_owner = self,
height   = btnSize,
label    = "+"..step,
position = { data.pos[1] + columnOffsetX, data.pos[2], rowZ },
scale    = buttonScale,
width    = btnSize,
    }
)
spawnedButtonCount = spawnedButtonCount + 1

-- Кнопка "-step" (столбик слева)
local subBtnId = counterId.."_btn_sub_"..step
local subFunc = function()
    click_resource_counter(-step, counterId)
end
self.setVar(subBtnId, subFunc)

createBtnAndSaveIndex(
    subBtnId,
    {
click_function = subBtnId,
color    = buttonColor,
font_color     = buttonFontColor,
font_size= btnSize * 0.7,
function_owner = self,
height   = btnSize,
label    = "−"..step,
position = { data.pos[1] - columnOffsetX, data.pos[2], rowZ },
scale    = buttonScale,
width    = btnSize,
    }
)
spawnedButtonCount = spawnedButtonCount + 1
  end
    end
end

-- Создаёт нередактируемые дисплеи (вычисляемые значения)
function createDisplay()
    for displayId, data in pairs(ref_buttonData.display) do
  -- Подпись дисплея
  local label = data.value
  -- Размер фона дисплея
  local size = data.size
  local tooltip = data.tooltip or ''

  if data.hideBG == true then
size = 0
  end

  -- Создаём кнопку-дисплей
  createBtnAndSaveIndex(
displayId,
{
    click_function = "click_none",
    color    = buttonColor,
    font_color     = buttonFontColor,
    font_size= data.size,
    function_owner = self,
    height   = size,
    label    = label,
    position = data.pos,
    scale    = buttonScale,
    tooltip  = tooltip,
    width    = size,
}
  )
    end
end

-- Создаёт кнопки-селекторы, открывающие диалог выбора значения
function createSelect()
    for selectId, data in pairs(ref_buttonData.select) do
  local label = spellAbilityLabels[data.value] or data.value
  local height = data.height or data.font_size * 1.4

  local funcName = selectId
  local func = function(obj, playerColor)
onClickSelect(selectId, playerColor)
  end
  self.setVar(funcName, func)

  createBtnAndSaveIndex(
selectId,
{
    click_function = funcName,
    color    = buttonColor,
    font_color     = buttonFontColor,
    font_size= data.font_size,
    function_owner = self,
    height   = height,
    label    = label,
    position = data.pos,
    scale    = buttonScale,
    width    = data.width,
}
  )
    end
end

-- Создаёт кнопки бросков костей (характеристики и навыки)
function createRolls()
    for rollId, data in pairs(ref_buttonData.roll) do
  local label = rollLabelCollection[rollId] or ''
  local tooltip = rollTextCollection[rollId]
  local height = data.height or data.font_size * 1.4

  local funcName = rollId
  local func = function(obj, playerColor)
rollParam(rollId, data.paramId, data.skillId, obj, playerColor)
  end
  self.setVar(funcName, func)

  createBtnAndSaveIndex(
rollId,
{
    click_function = funcName,
    color    = buttonColor,
    font_color     = buttonFontColor,
    font_size= data.font_size,
    function_owner = self,
    height   = height,
    label    = label,
    position = data.pos,
    scale    = buttonScale,
    tooltip  = tooltip,
    width    = data.width,
}
  )
    end
end

-- Создаёт кнопки бросков оружия
function createWeaponRolls()
    for i, data in ipairs(ref_buttonData.weapon_roll) do
        local funcName = "rollWeapon_" .. i
        local func = function(obj, playerColor)
            rollWeapon(i, obj, playerColor)
        end
        self.setVar(funcName, func)

        createBtnAndSaveIndex(
            "weapon_roll_" .. i,
            {
                click_function = funcName,
                color          = buttonColor,
                font_color     = buttonFontColor,
                font_size      = 180,
                function_owner = self,
                height         = 180,
                label          = "     ⚔️",
                position       = data.pos,
                scale          = buttonScale,
                tooltip        = "Бросок атаки и урона для этого оружия",
                width          = 180,
            }
        )
    end
end

-- Соответствие размера кубика встроенному объекту TTS (физические кости)
local diceTypeToObjectName = {
    [4]  = "Die_4",
    [6]  = "Die_6",
    [8]  = "Die_8",
    [10] = "Die_10",
    [12] = "Die_12",
    [20] = "Die_20",
}

-- Время (в секундах) до автоматического удаления кубиков со стола после броска
local DICE_CLEANUP_DELAY_SECONDS = 5
-- Таймаут ожидания, если кубик укатился/завис и не может остановиться
local DICE_SETTLE_TIMEOUT_SECONDS = 10
-- Сила подбрасывания кубиков вверх при броске
local DICE_TOSS_FORCE = 8
-- Сколько кадров ждать после spawnObject перед roll()/addForce() — свежесозданный
-- объект какое-то время физически "заморожен", одного кадра не хватало
local DICE_SPAWN_FREEZE_FRAMES = 5
-- На сколько смещать вперёд (дальше от листа, по той же локальной оси) каждый
-- следующий одновременный бросок, пока кубики предыдущего ещё не удалены
local DICE_THROW_FORWARD_STEP = -0.2
-- Насколько (в обычных мировых единицах, НЕ через масштаб листа) кубики
-- поднимаются над столом перед падением
local DICE_DROP_HEIGHT = 3
-- Локальная точка появления кубиков относительно листа по горизонтали:
-- X=0 (по центру), Z — в верхней части листа (отрицательный Z в этом
-- скрипте всегда означает "выше", см. позиции полей КД/хитов вверху файла).
-- Высота (Y) сюда специально не входит — см. DICE_DROP_HEIGHT ниже и
-- пояснение в rollPhysicalDiceGroups.
local DICE_SPAWN_LOCAL_POS = {0, -1.7 }

-- Слоты одновременных бросков: diceThrowSlotOccupied[i] == true, пока кубики
-- этого броска ещё лежат на столе. Новый бросок занимает первый свободный
-- слот и смещается дальше на DICE_THROW_FORWARD_STEP за каждый слот —
-- так кубики нового броска не падают на ещё не убранные кубики предыдущего.
local diceThrowSlotOccupied = {}

-- Бросает физические кубики одним броском и вызывает onComplete(results),
-- когда все они остановились. groups — список групп кубиков одного броска:
--   { {name="attack", diceType=20, diceCount=1}, {name="damage", diceType=6, diceCount=2} }
-- onComplete получает таблицу вида:
--   { attack = {values={17}, total=17}, damage = {values={4,5}, total=9} }
-- Для размеров кубика, которых нет среди стандартных моделей TTS, бросок
-- этой группы считается виртуально (dX), чтобы функция не ломалась.
--
-- ВАЖНО про несколько листов одновременно: вся эта функция и её состояние
-- (diceThrowSlotOccupied и другие local-переменные модуля) существуют внутри
-- скрипта КОНКРЕТНОГО объекта листа — TTS даёт каждому объекту со своим
-- скриптом полностью изолированное окружение Lua, даже если текст скрипта
-- одинаковый. Поэтому два листа на столе не видят и не делят между собой
-- эти переменные — коллизий слотов/бросков между разными листами не будет.
function rollPhysicalDiceGroups(groups, onComplete)
    local dice = {}
    local results = {}

    for _, group in ipairs(groups) do
        results[group.name] = {values = {}, total = 0}
    end

    -- Сколько физических кубиков реально понадобится (нестандартные размеры
    -- считаются виртуально и слот/смещение вперёд им не нужны)
    local physicalDiceNeeded = 0
    for _, group in ipairs(groups) do
        if diceTypeToObjectName[group.diceType] ~= nil then
            physicalDiceNeeded = physicalDiceNeeded + group.diceCount
        end
    end

    local slotIndex = nil

    if physicalDiceNeeded > 0 then
        slotIndex = 0
        while diceThrowSlotOccupied[slotIndex] == true do
            slotIndex = slotIndex + 1
        end
        diceThrowSlotOccupied[slotIndex] = true
    end

    -- Горизонтальная точка отсчёта (X/Z) — переводим только X/Z из локальных
    -- координат листа в мировые (учитывает поворот листа на столе).
    -- Высоту (Y) специально считаем отдельно, ниже, в обычных мировых
    -- единицах: positionToWorld() учитывает масштаб объекта листа, а лист
    -- обычно намного крупнее 1x1x1 — если пропустить высоту через него же,
    -- кубики "улетают" в разы выше стола, вместо того чтобы падать на него.
    local referencePos = self.positionToWorld({
        DICE_SPAWN_LOCAL_POS[1],
        0,
        DICE_SPAWN_LOCAL_POS[2] - DICE_THROW_FORWARD_STEP * (slotIndex or 0),
    })
    local tableY = self.getPosition()[2]

    local spawnCount = 0

    for _, group in ipairs(groups) do
        local objectName = diceTypeToObjectName[group.diceType]

        for i = 1, group.diceCount do
            if objectName == nil then
                -- Нестандартный размер кубика — физической модели нет, считаем виртуально
                local value = dX(group.diceType)
                table.insert(results[group.name].values, value)
                results[group.name].total = results[group.name].total + value
            else
                spawnCount = spawnCount + 1

                -- Небольшой разброс по X/Z (мировые единицы, без пересчёта через
                -- масштаб) — чтобы кубики не падали друг на друга, и высота
                -- над столом — фиксированная, кубики падают вниз, а не
                -- улетают вверх
                local position = {
                    referencePos[1] + (spawnCount - 3) * 0.6 + (math.random() - 0.5) * 0.3,
                    tableY + DICE_DROP_HEIGHT + spawnCount * 0.2,
                    referencePos[3] + (math.random() - 0.5) * 1.2,
                }

                local die = spawnObject({
                    type     = objectName,
                    position = position,
                    scale    = {1, 1, 1},
                })

                -- Пока кубик крутится — его нельзя брать в руки/двигать
                die.interactable = false

                -- Свежесозданный объект несколько кадров физически "заморожен" —
                -- roll()/addForce() нужно вызывать спустя паузу, иначе подброс не сработает
                Wait.frames(function()
                    if not die.isDestroyed() then
                        die.roll()
                        -- Небольшой подброс вверх (Impulse — мгновенный "толчок", не зависит от кадра)
                        die.addForce({0, DICE_TOSS_FORCE, 0}, 3)
                    end
                end, DICE_SPAWN_FREEZE_FRAMES)

                table.insert(dice, {obj = die, group = group.name})
            end
        end
    end

    -- Все кубики нестандартного размера — физических бросков не было,
    -- сразу отдаём виртуальный результат (слот не занимался — освобождать нечего)
    if #dice == 0 then
        onComplete(results)
        return
    end

    -- Сразу после roll() кубик ещё "resting" в течение пары кадров,
    -- поэтому проверку начинаем не мгновенно, а спустя несколько кадров
    -- после того, как выше уже подождали DICE_SPAWN_FREEZE_FRAMES
    Wait.frames(function()
        local function collectResults()
            for _, entry in ipairs(dice) do
                if not entry.obj.isDestroyed() then
                    local value = entry.obj.getValue()
                    table.insert(results[entry.group].values, value)
                    results[entry.group].total = results[entry.group].total + value
                end
            end
        end

        local function allowInteraction()
            for _, entry in ipairs(dice) do
                if not entry.obj.isDestroyed() then
                    entry.obj.interactable = true
                end
            end
        end

        local function cleanupDice()
            Wait.time(function()
                for _, entry in ipairs(dice) do
                    if not entry.obj.isDestroyed() then
                        entry.obj.destruct()
                    end
                end
                -- Слот освобождается только теперь — новые броски снова могут
                -- падать на это место, раз старые кубики убраны
                diceThrowSlotOccupied[slotIndex] = false
            end, DICE_CLEANUP_DELAY_SECONDS)
        end

        Wait.condition(
            function()
                collectResults()
                allowInteraction()
                onComplete(results)
                cleanupDice()
            end,
            function()
                for _, entry in ipairs(dice) do
                    if not entry.obj.isDestroyed() and not entry.obj.resting then
                        return false
                    end
                end
                return true
            end,
            DICE_SETTLE_TIMEOUT_SECONDS,
            function()
                -- Не все кубики успели остановиться вовремя — читаем то, что есть
                collectResults()
                allowInteraction()
                onComplete(results)
                cleanupDice()
            end
        )
    end, DICE_SPAWN_FREEZE_FRAMES + 10)
end

-- Выполняет бросок атаки и урона для выбранного оружия (физическими кубиками)
function rollWeapon(index, obj, playerColor)
    local function parseBonus(str)
        if str == nil or str == "" then return 0 end
        str = str:gsub("−", "-")
        str = str:gsub("[^%d%-%+]", "")
        return tonumber(str) or 0
    end

    local weaponName = ref_buttonData.textbox["textbox_Weapon_Name_"..index].value
    if weaponName == nil or weaponName == "" then
        weaponName = "Оружие " .. index
    end

    local hitBonusStr = ref_buttonData.textbox["textbox_Hit_"..index].value
    local hitBonus = parseBonus(hitBonusStr)

    local diceCountStr = ref_buttonData.textbox["textbox_Damage_Dice_Count_Type_"..index].value
    local diceTypeStr = ref_buttonData.textbox["textbox_Damage_Dice_Type_"..index].value
    local damageBonusStr = ref_buttonData.textbox["textbox_Damage_Bonus_"..index].value
    local damageNotes = ref_buttonData.textbox["textbox_Notes_"..index].value

    local diceCount = parseBonus(diceCountStr)
    local diceType = parseBonus(diceTypeStr)
    local damageBonus = parseBonus(damageBonusStr)

    local hasDamage = (diceType > 0) or (damageBonus ~= 0)
    if diceType > 0 and diceCount <= 0 then diceCount = 1 end

    -- Атака и урон бросаются одним броском: d20 на атаку и кубики урона
    -- (если есть) летят на стол вместе
    local groups = {{name = "attack", diceType = 20, diceCount = 1}}
    if diceType > 0 then
        table.insert(groups, {name = "damage", diceType = diceType, diceCount = diceCount})
    end

    rollPhysicalDiceGroups(groups, function(results)
        local roll20 = results.attack.total
        local totalAttack = roll20 + hitBonus

        local attackBonusSign = ""
        local attackBonusVal = ""
        if hitBonus > 0 then
            attackBonusSign = " + "
            attackBonusVal = tostring(hitBonus)
        elseif hitBonus < 0 then
            attackBonusSign = " − "
            attackBonusVal = tostring(math.abs(hitBonus))
        end
        local attackText = "d20(" .. roll20 .. ")" .. attackBonusSign .. attackBonusVal .. " = [b]" .. totalAttack .. "[/b]"

        local damageText = ""
        if hasDamage then
            if diceType > 0 then
                local rolls = results.damage.values
                local diceSum = results.damage.total
                local totalDamage = diceSum + damageBonus
                local rollsStr = table.concat(rolls, "+")
                local bonusSign = ""
                local bonusVal = ""
                if damageBonus > 0 then
                    bonusSign = " + "
                    bonusVal = tostring(damageBonus)
                elseif damageBonus < 0 then
                    bonusSign = " − "
                    bonusVal = tostring(math.abs(damageBonus))
                end
                damageText = diceCount .. "к" .. diceType .. "(" .. rollsStr .. ")" .. bonusSign .. bonusVal .. " = [b]" .. totalDamage .. "[/b]"
            else
                damageText = "[b]" .. damageBonus .. "[/b]"
            end
        end

        -- Формирование сообщения в чат
        local steam_name = Player[playerColor].steam_name
        local charSheetName = self.getName()
        if charSheetName == nil or charSheetName == "" then
            charSheetName = "Лист персонажа"
        end
        local playerColorRBB = convertColorNameIntoRgbString(playerColor)
        local charSheetColor = colorToHex(self.getColorTint())

        local msg = "["..playerColorRBB.."]"..steam_name.."[-]: [b]"..weaponName.."[/b] для ["..charSheetColor.."][i]"..charSheetName.."[/i][-]\n"
        msg = msg .. "• Атака: " .. attackText
        if hasDamage then
            msg = msg .. "  |  Урон: " .. damageText
            if damageNotes ~= nil and damageNotes ~= "" then
                msg = msg .. " [i](" .. damageNotes .. ")[/i]"
            end
        end

        broadcastToAll(msg)
    end)
end

-- Переводит цвет (r,g,b от 0 до 1) в HEX-строку
function colorToHex(color)
    local rHex, gHex, bHex = decimalToHex(color.r), decimalToHex(color.g), decimalToHex(color.b)

    return rHex .. '' .. gHex .. '' .. bHex
end

-- Переводит одну компоненту цвета (0..1) в двузначное HEX-значение
function decimalToHex(decimalNum)
    if decimalNum == 0 then
  return '00'
    else
  local hexStr = string.format("%X", math.floor(decimalNum * 256) - 1)
  local gapper = ''
  if string.len(hexStr) == 1 then
gapper = '0'
  end

  return gapper .. hexStr
    end
end

-- Выполняет бросок d20 (физическим кубиком) с учётом модификаторов
-- и выводит результат в чат всем игрокам
function rollParam(rollId, paramId, skillId, obj, playerColor)
    local paramBonusText = ''
    local skillBonusText = ''

    local paramBonus = 0
    local skillBonus = 0

    if (skillId == nil) then
  paramBonus = ref_buttonData.display["display_"..paramId].value

  local paramBonusSign = '+'
  if paramBonus < 0 then
paramBonusSign = '−'
  end
  paramBonusText = ' '..paramBonusSign..' '..math.abs(paramBonus)
    else
  skillBonus = tonumber(ref_buttonData.display["display_"..skillId].value)

  local skillBonusSign = '+'
  if skillBonus < 0 then
skillBonusSign = '−'
  end

  skillBonusText = ' '..skillBonusSign..' '..math.abs(skillBonus)
    end

    local steam_name = Player[playerColor].steam_name
    local charSheetName = obj.getName()
    local playerColorRBB = convertColorNameIntoRgbString(playerColor)
    local charSheetColor = colorToHex(obj.getColorTint())
    local rollName = rollTextCollection[rollId]

    rollPhysicalDiceGroups(
  {{name = "d20", diceType = 20, diceCount = 1}},
  function(results)
      local roll20 = results.d20.total
      local result = roll20 + paramBonus + skillBonus

      broadcastToAll(
    '['..playerColorRBB..']'..
    steam_name..'[-]: '
    ..rollName..' для ['..charSheetColor..'][i]'..charSheetName..'[/i][-]: '
    ..roll20
    ..paramBonusText
    ..skillBonusText
    ..' = [b]'..result..'[/b]'
      )
  end
    )
end

function convertColorNameIntoRgbString(colorName)
    -- See https://api.tabletopsimulator.com/player-color/
    local colorTable = {
  White = {r = 1, g = 1, b = 1},
  Brown = {r = 0.443, g = 0.231, b = 0.09},
  Red = {r = 0.856, g = 0.1, b = 0.094},
  Orange = {r = 0.956, g = 0.392, b = 0.113},
  Yellow = {r = 0.905, g = 0.898, b = 0.172},
  Green = {r = 0.192, g = 0.701, b = 0.168},
  Teal = {r = 0.129, g = 0.694, b = 0.607},
  Blue = {r = 0.118, g = 0.53, b = 1},
  Purple = {r = 0.627, g = 0.125, b = 0.941},
  Pink = {r = 0.96, g = 0.439, b = 0.807},
  Grey = {r = 0.5, g = 0.5, b = 0.5},
  Black = {r = 0.25, g = 0.25, b = 0.25},
    }

    return colorToHex(colorTable[colorName])
end

function d20()
    return dX(20)
end

function dX(diceSize)
    return math.random(1, diceSize)
end

-- Создаёт редактируемые текстовые поля персонажа.
-- Вызывается один раз при загрузке — и в заблокированном, и в
-- разблокированном состоянии поля создаются одинаково (как обычные
-- self.createInput); физической защитой при блокировке занимается отдельно
-- applyTextboxLockVisuals (разворот поля), вызываемая сразу после onload
-- и при каждом переключении блокировки.
function createTextbox()
    for textboxId, data in pairs(ref_buttonData.textbox) do
  -- Функция-обработчик ввода для конкретного поля
  local funcName = "textbox_"..textboxId
  local func = function(_, _, val, sel)
click_textbox(val, sel, textboxId)
  end

  local validation = 1 -- без валидации
  if data.validation then
validation = data.validation
  end

  self.setVar(funcName, func)

  createInputAndSaveIndex(
textboxId,
{
    alignment= data.alignment,
    color    = buttonColor,
    font_color     = buttonFontColor,
    font_size= data.font_size,
    function_owner = self,
    height   = (data.font_size * data.rows) + 24,
    input_function = funcName,
    label    = textboxLabelCollection[textboxId],
    position = data.pos,
    scale    = buttonScale,
    validation     = validation,
    value    = data.value,
    width    = data.width,
}
  )
    end
end

-- Создаёт кнопку и сохраняет её индекс TTS в таблицу по идентификатору элемента
-- (индекс нужен, чтобы потом обновлять кнопку через self.editButton)
function createBtnAndSaveIndex (btnId, params)
    self.createButton(params)
    local btnTable = self.getButtons()
    btnIndexByElementIdTable[btnId] = btnTable[#btnTable].index
end

-- Создаёт текстовое поле (input) и сохраняет его индекс TTS в таблицу по
-- идентификатору поля. У self.editInput нет параметра "id" — только числовой
-- index, который TTS назначает автоматически при создании, поэтому индекс
-- нужно зафиксировать сразу после создания через self.getInputs(). Безопасно,
-- поскольку self.createInput вызывается только здесь, один раз за партию,
-- при первичном создании листа в onload — поля больше никогда не
-- пересоздаются (блокировка лишь редактирует уже существующие через index).
function createInputAndSaveIndex(inputId, params)
    self.createInput(params)
    local inputTable = self.getInputs()
    inputIndexByElementIdTable[inputId] = inputTable[#inputTable].index
end