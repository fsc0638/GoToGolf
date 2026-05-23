#!/usr/bin/env python3
"""Build the Taiwan golf-course scorecards JSON.

Phase 1 (this script): seeds the file with every course in the official
115.01.19 directory PDF. Per-hole / per-tee data starts empty for every
course; subsequent runs of the research loop will fill them in
court-by-court, citing the source URL on each entry.

The PDF data — name, county, address, operator, hole count, phone — is
authoritative and verifiable from the source document, so those fields
ship as `verified` immediately.
"""
import json
from datetime import date

# (no, name, region, address, operator, area_ha, holes, phone)
COURSES = [
    (1,  "礁溪高爾夫球場",                "宜蘭縣", "宜蘭縣礁溪鄉林美村林尾路156號",          "亞達育樂事業股份有限公司",     49.929024,  18, "(03)9886691"),
    (2,  "新淡水高爾夫球場",              "新北市", "新北市淡水區八勢里3鄰八勢路300號",        "淡水企業股份有限公司",         55.5927,    18, "(02)28092466"),
    (3,  "林口高爾夫球場",                "新北市", "新北市林口區湖北里後湖50之1號",           "林口育樂事業股份有限公司",     72.1842,    18, "(02)26011211"),
    (4,  "北投國華高爾夫俱樂部球場",      "新北市", "新北市淡水區坪頂里小坪頂23之1號",         "大華觀光事業股份有限公司",     30.719,     18, "(02)86261281"),
    (5,  "臺灣高爾夫俱樂部球場",          "新北市", "新北市淡水區油車里中正路一段6巷32號",     "財團法人臺灣高爾夫俱樂部",     51.7677,    18, "(02)26212211"),
    (6,  "黃金海岸高爾夫球場",            "新北市", "新北市石門區草里里草埔尾5號",             "北海育樂股份有限公司",         70.39791,   18, "(02)26382930"),
    (7,  "八里國際高爾夫球場",            "新北市", "新北市林口區嘉寶里寶斗坑91號",            "北濱育樂事業股份有限公司",     84.2142,    18, "(02)26052222"),
    (8,  "東華高爾夫球場",                "新北市", "新北市林口區下福里7鄰93-1號",             "東華國際高爾夫育樂股份有限公司", 69.0631,  18, "(02)26062558"),
    (9,  "幸福高爾夫球場",                "新北市", "新北市林口區下福里71-1號",                "佳福育樂事業股份有限公司",     107.6687,   27, "(02)26062345"),
    (10, "翡翠高爾夫球場",                "新北市", "新北市萬里區北基里仁七街16-1號",          "磐達企業股份有限公司",         65.9276,    18, "(02)24924935"),
    (11, "美麗華高爾夫球場",              "新北市", "新北市林口區下福里下福路9號",             "美麗華開發股份有限公司",       82.1292,    18, "(02)26063456"),
    (12, "蓬萊高爾夫球場",                "新北市", "新北市林口區下福里下福路9號",             "美麗華開發股份有限公司",       82.6605,    18, "(02)26063456"),
    (13, "大屯高爾夫球場",                "新北市", "新北市淡水區埤島里商工路309號",           "大屯育樂開發股份有限公司",     24.8756,    13, "(02)26213271"),
    (14, "淡水濱海高爾夫球場",            "新北市", "新北市石門區尖鹿里尖仔仔路10號",          "長盛育樂股份有限公司",         59.7595,    18, "(02)26380679"),
    (15, "台北高爾夫俱樂部球場",          "桃園市", "桃園市蘆竹區坑子赤塗崎34之1號",           "財團法人台北高爾夫俱樂部",     170.0,      36, "(03)3241311"),
    (16, "長庚高爾夫俱樂部球場",          "桃園市", "桃園市龜山區舊路里長庚球場路66號",        "育志開發股份有限公司",         116.6979,   27, "(03)3296358"),
    (17, "桃園高爾夫球場",                "桃園市", "桃園市龍潭區九龍里29鄰悅華路100號",        "桃園育樂事業股份有限公司",     76.9284,    27, "(03)4803388"),
    (18, "第一高爾夫球場",                "桃園市", "桃園市蘆竹區坑子村7鄰貓尾崎50號",         "國盛育樂股份有限公司",         118.8042,   36, "(03)3245295"),
    (19, "揚昇高爾夫球場",                "桃園市", "桃園市楊梅區揚昇路256號",                 "揚昇育樂事業股份有限公司",     94.431,     18, "(03)4780099"),
    (20, "統帥高爾夫球場",                "桃園市", "桃園市蘆竹區營盤里六福一路195巷1弄8號",   "統帥育樂股份有限公司",         56.3701,    18, "(03)3221786"),
    (21, "楊梅高爾夫球場",                "桃園市", "桃園市楊梅區東流里13鄰崩坡73號",          "國盛育樂股份有限公司",         78.19279,   27, "(03)4780541"),
    (22, "永漢高爾夫球場",                "桃園市", "桃園市蘆竹區山腳里9鄰南山北路一段300號",  "永漢開發股份有限公司",         75.5557,    18, "(03)3245711"),
    (23, "大溪高爾夫球場",                "桃園市", "桃園市大溪區永福里日新路168號",           "大溪育樂股份有限公司",         101.3111,   27, "(03)3875699"),
    (24, "東方高爾夫球場",                "桃園市", "桃園市龜山區舊路里東方球場路100號",        "東方育樂事業股份有限公司",     88.6926,    18, "(03)3501212"),
    (25, "明台國際高爾夫球場",            "桃園市", "桃園市龍潭區三林里民生路439巷130號",      "明台育樂股份有限公司",         72.810891,  18, "(03)4995506"),
    (26, "新竹高爾夫俱樂部股份有限公司球場", "新竹縣", "新竹縣新豐鄉上坑村坑子口104號",         "新竹高爾夫俱樂部股份有限公司", 82.24595,   27, "(03)5596140"),
    (27, "山溪地高爾夫球場",              "新竹縣", "新竹縣關西鎮玉山里2鄰13號",               "山溪地育樂事業股份有限公司",   76.0876,    18, "(03)5476288"),
    (28, "再興高爾夫球場",                "新竹縣", "新竹縣湖口鄉長安村再興路350號",           "再興育樂開發股份有限公司",     67.2897,    18, "(03)5692318"),
    (29, "立益關西高爾夫球場",            "新竹縣", "新竹縣關西鎮湖肚段55號",                  "立益育樂股份有限公司",         99.7357,    18, "(03)5871842"),
    (30, "老爺關西高爾夫球場",            "新竹縣", "新竹縣關西鎮玉山里1鄰赤柯山1號",          "互馨育樂股份有限公司",         103.1845,   18, "(03)5476331"),
    (31, "旭陽高爾夫球場",                "新竹縣", "新竹縣關西鎮南新里新城段100號",           "旭陽育樂事業股份有限公司",     89.60407,   18, "(03)5476569"),
    (32, "寶山高爾夫球場",                "新竹縣", "新竹縣寶山鄉新城村寶新路2段465號",        "東光育樂股份有限公司",         72.0879,    18, "(03)5762888"),
    (33, "皇家高爾夫球場",                "苗栗縣", "苗栗縣頭屋鄉明德村1鄰明德路6之11號",      "耀德國際育樂股份有限公司",     117.595,    18, "(037)543122"),
    (34, "全國高爾夫球場",                "苗栗縣", "苗栗縣苑裡鎮石鎮里1鄰1之1號",             "全國高爾夫實業股份有限公司",   115.310916, 18, "(037)741166"),
    (35, "台中國際高爾夫球場",            "臺中市", "台中市北屯區民政里北坑巷21-8號",          "台中國際育樂股份有限公司",     110.125005, 27, "(04)22391172"),
    (36, "空軍清泉崗高爾夫球場",          "臺中市", "台中市清水區楊厝里和睦路2段305號",        "國防部空軍司令部",             82.0,       18, "(04)26200134"),
    (37, "霧峰高爾夫球場",                "臺中市", "台中市霧峰區峰谷里峰谷路668號",           "元扶企業股份有限公司",         77.0938,    18, "(04)23301199"),
    (38, "臺中縣豐原高爾夫俱樂部球場",    "臺中市", "台中市豐原區南嵩里水源路坪頂巷23號",      "社團法人台中市豐原高爾夫俱樂部", 48.6985,  18, "(04)25222835"),
    (39, "鴻禧太平高爾夫球場",            "臺中市", "台中市太平區頭汴里北田路265巷9號",        "同禧育樂股份有限公司",         50.068594,  18, "(04)22703470"),
    (40, "彰化高爾夫股份有限公司彰化球場", "彰化縣", "彰化縣彰化市延和里大埔路2巷101號",        "彰化高爾夫有限公司",           65.404833,  18, "(04)7135799"),
    (41, "台豐高爾夫球場",                "彰化縣", "彰化縣大村鄉福興村學府路77號",            "台豐興業股份有限公司",         67.9193,    18, "(04)8520101"),
    (42, "中華民國公教人員高爾夫研習會球場", "南投縣", "南投縣中興新村光明一路351號",            "國家文官學院",                 22.0863,     9, "(049)2332820"),
    (43, "南投縣松柏嶺高爾夫球場",        "南投縣", "南投縣名間鄉炭寮村炭頂巷36之1號",         "松柏嶺企業股份有限公司",       51.102493,  18, "(049)2732126"),
    (44, "南峰高爾夫球場",                "南投縣", "南投縣南投市鳳山路336-1號",               "南峰國際股份有限公司",         66.81495,   18, "(049)2254868"),
    (45, "嘉光高爾夫球場",                "嘉義縣", "嘉義縣水上鄉南鄉村鹿寮12號",              "嘉光育樂中心股份有限公司",     27.1433,     9, "(05)2536735"),
    (46, "東洋棕梠湖高爾夫球場",          "嘉義縣", "嘉義縣番路鄉新福村第三農場24號",          "東洋休閒觀光股份有限公司",     61.9578,    18, "(05)2590000"),
    (47, "台南高爾夫球場",                "臺南市", "台南市新化區礁坑里100號",                 "財團法人台南高爾夫俱樂部",     42.1073,    18, "(06)5901666"),
    (48, "南寶高爾夫球場",                "臺南市", "台南市大內區頭社里136號",                 "南寶鄉村實業股份有限公司",     81.9851,    27, "(06)5762546"),
    (49, "南一高爾夫球場",                "臺南市", "台南市關廟區布袋里長榮街500號",           "南一育樂事業股份有限公司",     91.4148,    18, "(06)5551121"),
    (50, "斑芝花高爾夫球場",              "臺南市", "台南市東山區東原里斑芝花坑39號",          "騰慶新國際開發有限公司",       108.4637,   27, "(06)6862208"),
    (51, "嘉南高爾夫球場",                "臺南市", "台南市官田區社子里六雙21號",              "嘉南開發事業股份有限公司",     74.3419,    18, "(06)6900800"),
    (52, "海軍左營高爾夫球場",            "高雄市", "高雄市左營區長壽路1號",                   "國防部海軍司令部",             24.7011,     9, "(07)5856921"),
    (53, "觀音山高爾夫球場",              "高雄市", "高雄市大樹區三和里三和路140號",           "觀音山高爾夫股份有限公司",     52.1454,    18, "(07)6578190"),
    (54, "高雄市信誼高爾夫球場",          "高雄市", "高雄市大樹區統嶺里信誼路1號",             "信誼育樂事業股份有限公司",     73.1823,    18, "(07)6563211"),
    (55, "大崗山高爾夫球場",              "高雄市", "高雄市田寮區西德里長山路1號",             "長山育樂股份有限公司",         103.75692,  18, "(07)6366411"),
    (56, "山湖觀高爾夫球場",              "屏東縣", "屏東縣高樹鄉廣興村中正路190號",           "大源開發股份有限公司",         116.4046,   27, "(08)7956600"),
    (57, "花蓮高爾夫球場",                "花蓮縣", "花蓮縣花蓮市化道路球崙1號",               "花蓮縣政府",                   39.6721,    18, "(03)8227528"),
]


# Verified summary data collected from web research 2026-05-23.
# Keyed by course `no`. Only totals — per-hole detail is not published
# online for any Taiwan course I could reach. Format:
#   "officialSite": …,
#   "sourceURL": …,
#   "summary": {"totalPar": …, "totalYardageByTee": {tee: yards, …}},
#   "notes": "…"
VERIFIED_SUMMARIES = {
    5: {  # 臺灣高爾夫俱樂部 (老淡水)
        "officialSite": "https://tgccgolf.com/",
        "sourceURL": "https://tgccgolf.com/",
        "summary": {"totalPar": 72, "totalYardageByTee": {}},
        "notes": "Par 72 confirmed (Tourism Administration directory + club site). "
                 "Per-hole table not published on tgccgolf.com/hole/ — page shows "
                 "only prose descriptions + photos.",
        "confidence": "partial",
    },
    11: {  # 美麗華高爾夫球場 (A course)
        "officialSite": "https://www.miramargolf.com/",
        "sourceURL": "http://www.gcs.org.tw/gcs/m_miramar.html",
        "summary": {"totalPar": 72, "totalYardageByTee": {"championship_A": 6835}},
        "notes": "Designed by Jack Nicklaus. A course total 6,835 yds. B course "
                 "(see #12 蓬萊) total 6,777 yds. Per-hole pars not reachable "
                 "through GCS (Big5 encoding garbled) or club site.",
        "confidence": "partial",
    },
    12: {  # 蓬萊高爾夫球場 — the B course of the Miramar facility
        "officialSite": "https://www.miramargolf.com/",
        "sourceURL": "http://www.gcs.org.tw/gcs/m_miramar.html",
        "summary": {"totalPar": 72, "totalYardageByTee": {"championship_B": 6777}},
        "notes": "Sister 18 of the Miramar facility (Nicklaus design). "
                 "Same operator/address as #11.",
        "confidence": "partial",
    },
    19: {  # 揚昇高爾夫球場
        "officialSite": "https://sunrise-golf.com.tw/",
        "sourceURL": "https://www.golf007.com/golf_course/taiwan/sunrise/",
        "summary": {
            "totalPar": 72,
            "totalYardageByTee": {"gold": 7200, "blue": 6610, "white": 6110}
        },
        "notes": "Robert Trent Jones Jr. design. Gold 7,200y, Blue 6,610y "
                 "(front 3,302 / back 3,308), White ~6,110y. Per-hole detail "
                 "blocked: sunrise-golf.com.tw returns 403 to automated fetch.",
        "confidence": "partial",
    },
    23: {  # 大溪高爾夫球場
        "officialSite": "http://www.tasheegolf.com.tw/",
        "sourceURL": "https://www.golfasian.com/golf-courses/taiwan-golf-courses/",
        "summary": {"totalPar": 72, "totalYardageByTee": {"championship_18": 7150}},
        "notes": "27-hole facility (East/Middle/West), 18-hole playable total "
                 "7,150 yds. Redesigned 1999 by Robert Trent Jones Jr. Official "
                 "site TLS cert is mismatched (ERR_TLS_CERT_ALTNAME_INVALID).",
        "confidence": "partial",
    },
}


def build_entry(row):
    no, name, region, addr, operator, area, holes, phone = row
    entry = {
        "no": no,
        "name": name,
        "region": region,
        "address": addr,
        "operator": operator,
        "approvedAreaHa": area,
        "approvedHoles": holes,
        "phone": phone,
        "officialSite": None,
        "scorecard": {
            "confidence": "unverified",   # unverified | partial | verified
            "totalPar": None,
            "totalYardageByTee": {},
            "tees": [],
            "holes": [],                  # [{"no":N,"par":P,"yardage":{...}}]
            "sourceURL": None,
            "notes": ""
        }
    }
    if no in VERIFIED_SUMMARIES:
        v = VERIFIED_SUMMARIES[no]
        entry["officialSite"] = v["officialSite"]
        s = entry["scorecard"]
        s["confidence"] = v["confidence"]
        s["totalPar"] = v["summary"]["totalPar"]
        s["totalYardageByTee"] = v["summary"]["totalYardageByTee"]
        s["tees"] = list(v["summary"]["totalYardageByTee"].keys())
        s["sourceURL"] = v["sourceURL"]
        s["notes"] = v["notes"]
    return entry


def main():
    assert len(COURSES) == 57, f"expected 57, got {len(COURSES)}"
    assert len({c[0] for c in COURSES}) == 57, "duplicate no"
    catalog = {
        "extractedAt": date.today().isoformat(),
        "source": {
            "name": "運動部核准開放使用及籌設高爾夫球場名冊（115年1月）",
            "file": "docs/115.01.19高爾夫球場名冊公布版.pdf",
            "publisher": "中華民國運動部",
            "totalCourses": len(COURSES)
        },
        "schemaNotes": (
            "Directory fields (no, name, region, address, operator, "
            "approvedAreaHa, approvedHoles, phone) are extracted directly "
            "from the source PDF and treated as verified. "
            "The scorecard block (totalPar, per-tee yardage, per-hole par) "
            "is filled in only when a corroborating official source can be "
            "reached — see scorecard.sourceURL and scorecard.confidence."
        ),
        "courses": [build_entry(r) for r in COURSES],
    }
    out = "/Users/fsc0638/Desktop/個人開發專案/GoToGolf/docs/taiwan_courses_scorecards.json"
    with open(out, "w", encoding="utf-8") as f:
        json.dump(catalog, f, ensure_ascii=False, indent=2)
        f.write("\n")
    print(f"wrote {len(COURSES)} course entries → {out}")


if __name__ == "__main__":
    main()
