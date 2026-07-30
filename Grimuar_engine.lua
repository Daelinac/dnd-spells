-- =============================================================================
-- GRIMUAR ENGINE — общий код, живущий в объекте "Скрытая База Заклинаний
-- (Master DB)", а не в каждой книге по отдельности.
--
-- КАК ЭТО ПОДКЛЮЧАЕТСЯ:
-- Книга при сборке библиотеки (buildLibraryCommand -> compileAndSpawnLibrary)
-- скачивает этот файл по GRIMUAR_ENGINE_URL и вклеивает его текст ПРЯМО В
-- СКРИПТ Master DB (между маленьким onLoad-стабом и сериализованными
-- IndexData/SpellsCache). То есть этот файл НЕ выполняется сам по себе как
-- отдельный объект — он становится частью скрипта Master DB. Поэтому:
--   - здесь НЕ должно быть своего onLoad() — он уже есть в стабе, который
--     подставляет книга, и второй onLoad в том же скрипте просто
--     перезапишет первый (Lua не выдаст ошибку, но онLoad-стаб перестанет
--     работать — задание self.locked/interactable/название пропадёт).
--   - "self" здесь, если понадобится — это сам объект Master DB
--     (BlockSquare, спрятанный за пределами стола), НЕ книга.
--
-- КАК ЭТИМ ПОЛЬЗУЮТСЯ КНИГИ:
-- Обычные глобальные таблицы (БЕЗ local!) TTS умеет читать с чужого объекта
-- напрямую через object.getTable("ИмяТаблицы") — без .call(), без задержки
-- на прыжок сообщения между объектами. Именно так книги уже читают
-- IndexData/SpellsCache — этот файл продолжает тот же паттерн.
--
-- Книга при подключении (connectToLibrary) читает каждую таблицу отсюда и
-- ПОДМЕШИВАЕТ её в свою одноимённую ЛОКАЛЬНУЮ переменную (не заменяет
-- переменную целиком, а копирует пары ключ-значение поверх неё). У книги
-- своя локальная копия при этом остаётся как ФОЛЛБЭК на случай, если
-- Master DB собрана без движка (старая версия/сеть подвела при сборке) —
-- тогда getTable вернёт nil, и книга просто продолжит работать на
-- собственной локальной копии, ничего не сломается.
--
-- ЧТО ЗНАЧИТ ЭТО ДЛЯ ОБНОВЛЕНИЙ:
-- Чтобы поправить перевод/добавить новый тип урона и т.п. — правите ТОЛЬКО
-- этот файл на GitHub, затем один раз пересобираете библиотеку (ПКМ по
-- книге -> Настройки -> Глобальные настройки -> Создать библиотеку — она
-- же теперь скачает и этот файл). Новое значение подхватят ВСЕ книги при
-- следующем подключении к базе, без необходимости лезть в код каждой книги.
-- =============================================================================

-- Локализация классов для отображения в карточке
MODIFIERS_RU = {
    spellcasting = "БАЗ", -- Базовая характеристика заклинателя
    str = "СИЛ",
    dex = "ЛОВ",
    con = "ТЕЛ",
    int = "ИНТ",
    wis = "МУД",
    cha = "ХАР",
    pb = "БМ" -- Бонус мастерства
}

-- Родительный падеж характеристик для текста спасброска ("Спасбросок Ловкости")
ABILITY_RU_GENITIVE = {
    str = "Силы", dex = "Ловкости", con = "Телосложения",
    int = "Интеллекта", wis = "Мудрости", cha = "Харизмы"
}

-- Человекочитаемые подписи для известных id эффектов (используются, только если
-- у эффекта в данных нет собственного label)
EFFECT_LABELS_RU_FALLBACK = {
    primary = "Основной эффект", secondary = "Доп. эффект",
    splash = "Всплеск", jump = "Прыжок", explosion = "Взрыв"
}

-- Словарь для перевода типов урона на русский язык
DAMAGE_TYPES_RU = {
    force       = "Силовое поле",
    fire        = "Огонь",
    cold        = "Холод",
    necrotic    = "Некротический",
    psychic     = "Психический",
    radiant     = "Излучение",
    acid        = "Кислота",
    lightning   = "Молния",
    thunder     = "Звук",
    poison      = "Яд",
    bludgeoning = "Дробящий",
    piercing    = "Колющий",
    slashing    = "Рубящий",
    healing     = "Лечение", -- Добавлено для лечащих заклинаний
    temp_max_hp = "Врем. макс. ХП", -- Новый формат: Aid и подобные
    variable    = "Различный"
}

-- Локализация классов для отображения в карточке
CLASS_NAMES_RU = {
    ["wizard"] = "Волшебник", ["sorcerer"] = "Чародей", ["warlock"] = "Колдун",
    ["bard"] = "Бард", ["cleric"] = "Жрец", ["druid"] = "Друид",
    ["paladin"] = "Паладин", ["ranger"] = "Следопыт", ["artificer"] = "Изобретатель"
}

-- Фоллбек-цвета для школ (на случай, если в самом заклинании вдруг не окажется school_color)
DEFAULT_SCHOOL_COLORS = {
    ["trs"] = "#9b59b6", ["evo"] = "#e74c3c", ["abj"] = "#2980b9",
    ["con"] = "#e67e22", ["div"] = "#f1c40f", ["enc"] = "#4a90e2",
    ["ill"] = "#2ecc71", ["nec"] = "#7f8c8d"
}

-- Таблица для быстрой трансформации регистра кириллицы
CYRILLIC_TRANSFORM = {
    ["А"]="а", ["Б"]="б", ["В"]="в", ["Г"]="г", ["Д"]="д", ["Е"]="е", ["Ё"]="ё",
    ["Ж"]="ж", ["З"]="з", ["И"]="и", ["Й"]="й", ["К"]="к", ["Л"]="л", ["М"]="м",
    ["Н"]="н", ["О"]="о", ["П"]="п", ["Р"]="р", ["С"]="с", ["Т"]="т", ["У"]="у",
    ["Ф"]="ф", ["Х"]="х", ["Ц"]="ц", ["Ч"]="ч", ["Ш"]="ш", ["Щ"]="щ", ["Ъ"]="ъ",
    ["Ы"]="ы", ["Ь"]="ь", ["Э"]="э", ["Ю"]="ю", ["Я"]="я"
}

-- Формы слов для времени накладывания ("1 Минута" / "10 Минут" и т.п.)
ACTIVATION_UNIT_FORMS_RU = {
    minute = { "Минута", "Минуты", "Минут" },
    hour   = { "Час", "Часа", "Часов" },
    day    = { "День", "Дня", "Дней" }
}

ACTIVATION_TYPE_LABELS_RU = {
    action   = "Действие",
    bonus    = "Бонусное действие",
    reaction = "Реакция",
    special  = "Особое"
}

-- =============================================================================
-- ФАЗА 1 — ЧТЕНИЕ ЛИСТА ПЕРСОНАЖА
-- =============================================================================
-- В отличие от словарей выше, это ФУНКЦИИ, а не данные — их не подмешать
-- поверх локальной таблицы книги. Книга вызывает их через
-- db.call("имяФункции", { ...параметры... }) — TTS передаёт функции РОВНО
-- ОДИН параметр, поэтому КАЖДАЯ функция здесь принимает единственную
-- таблицу params и сама достаёт из неё нужные поля (см. ниже).
--
-- Эти функции работают с УЖЕ ГОТОВЫМИ данными листа (sheetData —
-- результат sheet.call("getButtonData"), книга получает его сама и просто
-- передаёт сюда как параметр) — здесь нет ни одного обращения к GUID,
-- к листу напрямую, к self книги и т.п. Чистые функции: одинаковые входные
-- данные -> одинаковый результат, ничего не хранят между вызовами.
--
-- В книге у каждой из них оставлена ЛОКАЛЬНАЯ КОПИЯ этой же логики как
-- ФОЛЛБЭК — если Master DB не собрана с движком (старая сборка / сеть
-- подвела при сборке) или объект не найден на столе, книга просто считает
-- сама, как и раньше. Правки логики отсюда пересборкой библиотеки
-- подхватят все книги; фоллбэк-копии в книге при этом трогать не нужно.
-- =============================================================================

-- Ключи для чтения ГОТОВЫХ (уже посчитанных листом) итоговых значений —
-- см. комментарии в самой книге (ЗАКЛИНАТОР) для подробностей по каждому.
local CHARACTER_SHEET_ABILITY_KEYS = {
    STR = "display_STR", DEX = "display_DEX", CON = "display_CON",
    INT = "display_INT", WIS = "display_WIS", CHA = "display_CHA",
}
local CHARACTER_SHEET_SAVE_KEYS = {
    STR = "display_STR_savethrow", DEX = "display_DEX_savethrow", CON = "display_CON_savethrow",
    INT = "display_INT_savethrow", WIS = "display_WIS_savethrow", CHA = "display_CHA_savethrow",
}
local CHARACTER_SHEET_SKILL_KEYS = {
    Athletics = "display_Athletics",
    Acrobatics = "display_Acrobatics",
    Stealth = "display_Stealth",
    SleightOfHand = "display_Sleight_of_hand",
    Arcana = "display_Arcana",
    History = "display_History",
    Investigation = "display_Investigation",
    Nature = "display_Nature",
    Religion = "display_Religion",
    AnimalHandling = "display_Animal_Handling",
    Insight = "display_Insight",
    Medicine = "display_Medicine",
    Perception = "display_Perception",
    Survival = "display_Survival",
    Performance = "display_Performance",
    Deception = "display_Deception",
    Intimidation = "display_Intimidation",
    Persuasion = "display_Persuasion",
}
local CHARACTER_SHEET_PROFICIENCY_KEY = "display_Proficiency"
local CHARACTER_SHEET_SPELL_ATTACK_BONUS_KEY = "textbox_Spell_Attack_Bonus"
local CHARACTER_SHEET_SPELL_SAVE_DC_KEY = "textbox_Spell_Save_DC"
local CHARACTER_SHEET_WEAPON_SLOTS = {
    { name = "textbox_Weapon_Name_1", hit = "textbox_Hit_1", diceCount = "textbox_Damage_Dice_Count_Type_1", diceType = "textbox_Damage_Dice_Type_1", bonus = "textbox_Damage_Bonus_1", notes = "textbox_Notes_1" },
    { name = "textbox_Weapon_Name_2", hit = "textbox_Hit_2", diceCount = "textbox_Damage_Dice_Count_Type_2", diceType = "textbox_Damage_Dice_Type_2", bonus = "textbox_Damage_Bonus_2", notes = "textbox_Notes_2" },
    { name = "textbox_Weapon_Name_3", hit = "textbox_Hit_3", diceCount = "textbox_Damage_Dice_Count_Type_3", diceType = "textbox_Damage_Dice_Type_3", bonus = "textbox_Damage_Bonus_3", notes = "textbox_Notes_3" },
    { name = "textbox_Weapon_Name_4", hit = "textbox_Hit_4", diceCount = "textbox_Damage_Dice_Count_Type_4", diceType = "textbox_Damage_Dice_Type_4", bonus = "textbox_Damage_Bonus_4", notes = "textbox_Notes_4" },
    { name = "textbox_Weapon_Name_5", hit = "textbox_Hit_5", diceCount = "textbox_Damage_Dice_Count_Type_5", diceType = "textbox_Damage_Dice_Type_5", bonus = "textbox_Damage_Bonus_5", notes = "textbox_Notes_5" },
    { name = "textbox_Weapon_Name_6", hit = "textbox_Hit_6", diceCount = "textbox_Damage_Dice_Count_Type_6", diceType = "textbox_Damage_Dice_Type_6", bonus = "textbox_Damage_Bonus_6", notes = "textbox_Notes_6" },
    { name = "textbox_Weapon_Name_7", hit = "textbox_Hit_7", diceCount = "textbox_Damage_Dice_Count_Type_7", diceType = "textbox_Damage_Dice_Type_7", bonus = "textbox_Damage_Bonus_7", notes = "textbox_Notes_7" },
}

function parseSheetNumber(params)
    local v = params.v
    if type(v) == "number" then return v end
    if type(v) == "string" and v ~= "" then return tonumber(v) end
    return nil
end

function textboxValue(params)
    local sheetData, key = params.sheetData, params.key
    local entry = sheetData.textbox and sheetData.textbox[key]
    return entry and entry.value or nil
end

function getAbilityModifier(params)
    local sheetData, abilityCode = params.sheetData, params.abilityCode
    local key = CHARACTER_SHEET_ABILITY_KEYS[abilityCode]
    return key and sheetData.display[key] and parseSheetNumber({ v = sheetData.display[key].value }) or nil
end

function getSaveBonus(params)
    local sheetData, abilityCode = params.sheetData, params.abilityCode
    local key = CHARACTER_SHEET_SAVE_KEYS[abilityCode]
    return key and sheetData.display[key] and parseSheetNumber({ v = sheetData.display[key].value }) or nil
end

function getSkillBonus(params)
    local sheetData, skillCode = params.sheetData, params.skillCode
    local key = CHARACTER_SHEET_SKILL_KEYS[skillCode]
    return key and sheetData.display[key] and parseSheetNumber({ v = sheetData.display[key].value }) or nil
end

function getProficiencyBonus(params)
    local sheetData = params.sheetData
    return sheetData.display[CHARACTER_SHEET_PROFICIENCY_KEY]
        and parseSheetNumber({ v = sheetData.display[CHARACTER_SHEET_PROFICIENCY_KEY].value }) or nil
end

function getSpellAttackBonusFromSheet(params)
    local sheetData = params.sheetData
    local entry = sheetData.textbox and sheetData.textbox[CHARACTER_SHEET_SPELL_ATTACK_BONUS_KEY]
    return entry and parseSheetNumber({ v = entry.value }) or nil
end

function getSpellSaveDCFromSheet(params)
    local sheetData = params.sheetData
    local entry = sheetData.textbox and sheetData.textbox[CHARACTER_SHEET_SPELL_SAVE_DC_KEY]
    return entry and parseSheetNumber({ v = entry.value }) or nil
end

function getCharacterWeapons(params)
    local sheetData = params.sheetData
    local list = {}
    if not sheetData or not sheetData.textbox then return list end

    for _, slot in ipairs(CHARACTER_SHEET_WEAPON_SLOTS) do
        local name = textboxValue({ sheetData = sheetData, key = slot.name })
        if name and name ~= "" then
            table.insert(list, {
                name = name,
                hitBonus = parseSheetNumber({ v = textboxValue({ sheetData = sheetData, key = slot.hit }) }),
                diceCount = parseSheetNumber({ v = textboxValue({ sheetData = sheetData, key = slot.diceCount }) }),
                diceType = parseSheetNumber({ v = textboxValue({ sheetData = sheetData, key = slot.diceType }) }),
                damageBonus = parseSheetNumber({ v = textboxValue({ sheetData = sheetData, key = slot.bonus }) }),
                damageTypeNote = textboxValue({ sheetData = sheetData, key = slot.notes }),
            })
        end
    end

    return list
end

function findWeaponOnSheet(params)
    local sheetData, nameHint = params.sheetData, params.nameHint
    local weapons = getCharacterWeapons({ sheetData = sheetData })
    if #weapons == 0 then return nil end

    if nameHint and nameHint ~= "" then
        local lowerHint = string.lower(nameHint)
        for _, w in ipairs(weapons) do
            if string.find(string.lower(w.name), lowerHint, 1, true) then
                return w
            end
        end
    end

    return weapons[1]
end

function buildWeaponDamageFormula(params)
    local weapon = params.weapon
    if not weapon or not weapon.diceCount or not weapon.diceType then return nil end

    local formula = weapon.diceCount .. "d" .. weapon.diceType
    if weapon.damageBonus and weapon.damageBonus ~= 0 then
        formula = formula .. (weapon.damageBonus > 0 and "+" or "") .. weapon.damageBonus
    end
    return formula
end

-- Диапазон уровней персонажа для скейлинга ЗАГОВОРОВ — чистая часть
-- getDefaultCantripTierIndex из книги (сама привязка к GUID листа и чтение
-- lvl остаются в книге, сюда передаётся уже готовое число).
function cantripTierIndexForLevel(params)
    local lvl = tonumber(params.lvl)
    if not lvl then return 0 end

    if lvl >= 17 then return 3
    elseif lvl >= 11 then return 2
    elseif lvl >= 5 then return 1
    else return 0 end
end

-- =============================================================================
-- ФАЗА 2 — ПРЕЗЕНТАЦИОННЫЕ ХЕЛПЕРЫ (только то, что НЕ горячий путь)
-- =============================================================================
-- ВАЖНО: большинство презентационных хелперов книги (getEffectLabel,
-- getActivationText, buildAttackModifierSuffix, spellHasAnyScaling/Damage,
-- getSpellSharedVariants, getSpellEffects) вызываются внутри
-- computeSpellButtonTexts — а эта функция пересчитывает текст КАЖДОЙ кнопки
-- заклинания при КАЖДОЙ перерисовке списка (открытие библиотеки, скролл,
-- поиск). Перенос их сюда добавил бы сетевой .call() на каждую видимую
-- кнопку при каждом скролле — это не "безопасный перенос", а реальное
-- подвисание списка. Поэтому они ОСТАЮТСЯ в книге.
--
-- cleanDescription — исключение: вызывается только при ОТКРЫТИИ конкретной
-- карточки заклинания (клик по спеллу), не при скролле списка — раз на
-- клик, ничтожный оверхед. Единственный безопасный кандидат этой фазы.
-- =============================================================================
function cleanDescription(params)
    local desc = params.desc
    if not desc then return "Описание отсутствует." end
    local d = tostring(desc)
    d = string.gsub(d, "<p>", "")
    d = string.gsub(d, "</p>", "\n")
    d = string.gsub(d, "<br/?>", "\n")
    d = string.gsub(d, "<li>", " • ")
    d = string.gsub(d, "</li>", "\n")
    d = string.gsub(d, "<ul>", "")
    d = string.gsub(d, "</ul>", "")
    d = string.gsub(d, "<ol>", "")
    d = string.gsub(d, "</ol>", "")
    return d
end

-- =============================================================================
-- ФАЗА 2 (продолжение) — ОСТАЛЬНЫЕ ПРЕЗЕНТАЦИОННЫЕ ХЕЛПЕРЫ
-- =============================================================================
-- getSpellEffects НЕ переносится: это тривиальный однострочник
-- (spell.system.effects or {}), который используют ВНУТРИ СЕБЯ почти все
-- функции ниже — если бы getSpellEffects тоже была .call()-обёрткой,
-- каждый клик по карточке заклинания стал бы делать 5-8 лишних сетевых
-- прыжков только ради этой мелочи (спрятанных внутри других вызовов).
-- Поэтому функции ниже сами берут spell.system.effects напрямую.
-- =============================================================================

local function engineGetSpellEffects(spell)
    local sys = spell and spell.system or {}
    return sys.effects or {}
end

function getEffectLabel(params)
    local effect = params.effect
    return effect.label or EFFECT_LABELS_RU_FALLBACK[effect.id] or effect.id or "Эффект"
end

function spellHasAnyScaling(params)
    local spell = params.spell
    for _, e in ipairs(engineGetSpellEffects(spell)) do
        if e.scaling and e.scaling.mode and e.scaling.mode ~= "none" then return true end
    end
    return false
end

function getSpellSharedVariants(params)
    local spell = params.spell
    for _, e in ipairs(engineGetSpellEffects(spell)) do
        if e.damage then
            for _, dmg in ipairs(e.damage) do
                if dmg.variants and #dmg.variants > 0 then return dmg.variants end
            end
        end
    end
    return nil
end

function spellHasAnyDamage(params)
    local spell = params.spell
    for _, e in ipairs(engineGetSpellEffects(spell)) do
        if e.damage and #e.damage > 0 then return true end
    end
    return false
end

-- Локальный хелпер склонения числительных ("1 Минута"/"10 Минут") — нужен
-- только здесь, поэтому не выносится отдельной .call()-функцией.
local function engineDeclOfNum(n, forms)
    local mod100 = math.abs(n) % 100
    local mod10 = mod100 % 10
    if mod100 > 10 and mod100 < 20 then return forms[3] end
    if mod10 > 1 and mod10 < 5 then return forms[2] end
    if mod10 == 1 then return forms[1] end
    return forms[3]
end

function getActivationText(params)
    local sys = params.sys
    local act = sys.activation or {}
    local forms = ACTIVATION_UNIT_FORMS_RU[act.type]
    if forms then
        local cost = act.cost or 1
        if cost == 1 then return forms[1] end
        return cost .. " " .. engineDeclOfNum(cost, forms)
    end
    if ACTIVATION_TYPE_LABELS_RU[act.type] then
        return ACTIVATION_TYPE_LABELS_RU[act.type]
    end
    if sys.display and sys.display.activation and sys.display.activation ~= "" then
        return sys.display.activation
    end
    return "—"
end

function buildAttackModifierSuffix(params)
    local effect = params.effect
    if not effect.attackModifiers or #effect.attackModifiers == 0 then return "" end
    local names = {}
    for _, m in ipairs(effect.attackModifiers) do
        table.insert(names, MODIFIERS_RU[string.lower(m)] or m)
    end
    return " + " .. table.concat(names, " + ")
end
