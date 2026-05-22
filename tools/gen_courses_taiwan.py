#!/usr/bin/env python3
"""Generate courses_taiwan.json for all 58 operating Taiwan golf courses.

Course name / region / facility hole-count are sourced from the Wikipedia
list 〈台灣高爾夫球場列表〉 and the Tourism Administration directory — those
fields are verifiable.

Per-hole par is NOT individually verified: most Taiwan clubs are members-
only and do not publish full scorecards. Each course therefore gets a
STANDARD par template (18-hole = par 72, 9-hole = par 36) that players are
expected to correct against the real scorecard on the first tee. The app
surfaces this caveat in the UI and lets users edit the pars.

Facilities with 27 or 36 holes are represented as a single 18-hole
playable round (the app scores 18); 9-hole facilities stay 9.
"""
import json

# Standard par templates — front nine + back nine total 72.
PAR18 = [4, 5, 3, 4, 4, 3, 4, 5, 4,  4, 4, 3, 5, 4, 4, 3, 4, 5]
PAR9 = [4, 5, 3, 4, 4, 3, 4, 5, 4]
assert sum(PAR18) == 72 and sum(PAR9) == 36

# (id, name, region, played-holes)  — played-holes is 9 or 18.
COURSES = [
    # --- 新北市 ---
    ("TW-TAIWAN-GC",       "臺灣高爾夫俱樂部",       "新北市", 18),
    ("TW-HUIHUANG",        "揮皇高爾夫俱樂部",       "新北市", 18),
    ("TW-DATUN",           "大屯高爾夫球場",         "新北市", 18),
    ("TW-KUOHUA",          "北投國華高爾夫俱樂部",   "新北市", 18),
    ("TW-BALI",            "八里國際高爾夫俱樂部",   "新北市", 18),
    ("TW-MIRAMAR",         "美麗華高爾夫俱樂部",     "新北市", 18),
    ("TW-LINKOU",          "林口高爾夫俱樂部",       "新北市", 18),
    ("TW-HSINGFU",         "幸福高爾夫俱樂部",       "新北市", 18),
    ("TW-TUNGHUA",         "東華高爾夫俱樂部",       "新北市", 18),
    ("TW-GOLDCOAST",       "黃金海岸高爾夫球場",     "新北市", 18),
    ("TW-OCEANVIEW",       "濱海高爾夫俱樂部",       "新北市", 18),
    ("TW-EMERALD",         "翡翠高爾夫俱樂部",       "新北市", 18),
    # --- 桃園市 ---
    ("TW-TAIPEI",          "台北高爾夫俱樂部",       "桃園市", 18),
    ("TW-TUNGSHUAI",       "統帥高爾夫俱樂部",       "桃園市", 18),
    ("TW-FIRST",           "第一高爾夫俱樂部",       "桃園市", 18),
    ("TW-YUNGHAN",         "永漢高爾夫俱樂部",       "桃園市", 18),
    ("TW-CHANGGUNG",       "長庚高爾夫俱樂部",       "桃園市", 18),
    ("TW-ORIENTAL",        "東方高爾夫俱樂部",       "桃園市", 18),
    ("TW-YANGMEI",         "楊梅高爾夫俱樂部",       "桃園市", 18),
    ("TW-SUNRISE",         "揚昇高爾夫鄉村俱樂部",   "桃園市", 18),
    ("TW-TAOYUAN",         "桃園高爾夫俱樂部",       "桃園市", 18),
    ("TW-LUNGTAN",         "龍潭高爾夫俱樂部",       "桃園市", 18),
    ("TW-TASHEE",          "大溪高爾夫俱樂部",       "桃園市", 18),
    # --- 新竹縣 ---
    ("TW-HSINCHU",         "新竹高爾夫俱樂部",       "新竹縣", 18),
    ("TW-TSAIHSING",       "再興高爾夫俱樂部",       "新竹縣", 18),
    ("TW-SHANCHITI",       "山溪地高爾夫俱樂部",     "新竹縣", 18),
    ("TW-LIYI",            "立益高爾夫俱樂部",       "新竹縣", 18),
    ("TW-LAOYEH-KUANHSI",  "老爺關西高爾夫俱樂部",   "新竹縣", 18),
    ("TW-HSUYANG",         "旭陽高爾夫俱樂部",       "新竹縣", 18),
    ("TW-BAOSHAN",         "寶山高爾夫俱樂部",       "新竹縣", 18),
    # --- 苗栗縣 ---
    ("TW-ROYAL",           "皇家高爾夫俱樂部",       "苗栗縣", 18),
    ("TW-NATIONWIDE",      "全國高爾夫俱樂部",       "苗栗縣", 18),
    # --- 台中市 ---
    ("TW-TAICHUNG-INTL",   "台中國際高爾夫球場",     "台中市", 18),
    ("TW-TAICHUNG",        "台中高爾夫球場",         "台中市", 18),
    ("TW-HONGHSI-TAIPING", "鴻禧太平高爾夫俱樂部",   "台中市", 9),
    ("TW-WUFENG",          "霧峰高爾夫俱樂部",       "台中市", 18),
    ("TW-FENGYUAN",        "豐原高爾夫俱樂部",       "台中市", 18),
    ("TW-CHINGCHUANKANG",  "空軍清泉崗高爾夫俱樂部", "台中市", 18),
    # --- 彰化縣 ---
    ("TW-CHANGHUA",        "彰化高爾夫俱樂部",       "彰化縣", 18),
    ("TW-TAIFONG",         "台豐高爾夫俱樂部",       "彰化縣", 18),
    # --- 南投縣 ---
    ("TW-NANFENG",         "南峰高爾夫俱樂部",       "南投縣", 18),
    ("TW-CHUNGHSING",      "中興新村高爾夫球場",     "南投縣", 9),
    ("TW-SUNGPOLING",      "松柏嶺高爾夫俱樂部",     "南投縣", 18),
    # --- 嘉義縣 ---
    ("TW-PALM-LAKE",       "棕梠湖高爾夫俱樂部",     "嘉義縣", 18),
    ("TW-CHIAKUANG",       "嘉光高爾夫俱樂部",       "嘉義縣", 9),
    # --- 台南市 ---
    ("TW-PANCHIHHUA",      "斑芝花高爾夫俱樂部",     "台南市", 18),
    ("TW-CHIANAN",         "嘉南高爾夫俱樂部",       "台南市", 18),
    ("TW-TAINAN",          "台南高爾夫俱樂部",       "台南市", 18),
    ("TW-NANPAO",          "南寶高爾夫俱樂部",       "台南市", 18),
    ("TW-NANYI",           "南一高爾夫俱樂部",       "台南市", 18),
    # --- 高雄市 ---
    ("TW-KUANYINSHAN",     "觀音山高爾夫俱樂部",     "高雄市", 18),
    ("TW-HSINYI",          "信誼高爾夫俱樂部",       "高雄市", 18),
    ("TW-TAKANGSHAN",      "大崗山高爾夫俱樂部",     "高雄市", 18),
    ("TW-NAVY",            "海軍高爾夫俱樂部",       "高雄市", 9),
    ("TW-DAVIDCAMP",       "大衛營高爾夫俱樂部",     "高雄市", 9),
    # --- 屏東縣 ---
    ("TW-SHANHUKUAN",      "山湖觀高爾夫球場",       "屏東縣", 18),
    # --- 宜蘭縣 ---
    ("TW-CHIAOHSI",        "礁溪高爾夫俱樂部",       "宜蘭縣", 18),
    # --- 花蓮縣 ---
    ("TW-HUALIEN",         "花蓮高爾夫俱樂部",       "花蓮縣", 18),
]


def build(course):
    cid, name, region, played = course
    template = PAR9 if played == 9 else PAR18
    holes = [{"number": i + 1, "par": p} for i, p in enumerate(template)]
    total = sum(template)
    return {
        "id": cid,
        "name": name,
        "region": region,
        "holes": holes,
        "ratings": {
            "white": {"courseRating": float(total), "slopeRating": 113}
        },
    }


def main():
    assert len({c[0] for c in COURSES}) == len(COURSES), "duplicate id"
    catalog = [build(c) for c in COURSES]
    out = "/Users/fsc0638/Desktop/個人開發專案/GoToGolf/App/Resources/courses_taiwan.json"
    with open(out, "w", encoding="utf-8") as f:
        json.dump(catalog, f, ensure_ascii=False, indent=2)
        f.write("\n")
    nine = sum(1 for c in COURSES if c[3] == 9)
    print(f"wrote {len(catalog)} courses ({nine} nine-hole, {len(catalog)-nine} eighteen-hole)")


if __name__ == "__main__":
    main()
