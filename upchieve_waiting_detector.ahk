#Requires AutoHotkey v2.0
#Include FindTextv2.ahk
#Include alphabet.ahk
#Include student_database.ahk

; SearchZone class for defining search areas
class SearchZone {
    __New(x1 := 0, y1 := 0, x2 := 0, y2 := 0, width := 0, height := 0) {
        this.x1 := x1
        this.y1 := y1

        ; Use width/height if provided, otherwise use x2/y2
        if (width > 0)
            this.x2 := x1 + width
        else
            this.x2 := x2

        if (height > 0)
            this.y2 := y1 + height
        else
            this.y2 := y2
    }

    ToString() {
        return "SearchZone(" . Round(this.x1) . "," . Round(this.y1) . " to " . Round(this.x2) . "," . Round(this.y2) . ")"
    }
}

; FindText wrapper for multiple search zones
FindTextInZones(target, zone1, zone2 := "", err1 := 0.15, err2 := 0.10, verbose := false) {
    startTime := A_TickCount

    ; Extract target ID from pattern for logging
    targetId := ""
    if (target != "") {
        ; Extract ID from pattern like "|<WaitingTarget>*123$45.hex..."
        if (RegExMatch(target, "\|<([^>]+)>", &match))
            targetId := match[1]
        else if (RegExMatch(target, "<([^>]+)>", &match))
            targetId := match[1]
        else
            targetId := "Unknown"
    }

    if (verbose) {
        WriteLog("VERBOSE: FindTextInZones - target=" . targetId . " zone1=" . zone1.ToString() . " err1=" . Format("{:.2f}", err1) . " err2=" . Format("{:.2f}", err2))
        if (zone2 != "" && IsObject(zone2))
            WriteLog("VERBOSE: FindTextInZones - zone2=" . zone2.ToString())
    }

    ; Try first zone
    if (result := FindText(, , zone1.x1, zone1.y1, zone1.x2, zone1.y2, err1, err2, target, 0,1)) {
        SearchStats.searchTimeMs := A_TickCount - startTime
        SearchStats.foundInZone := "zone1"
        ; Log all successful results
        WriteLog("DEBUG: FindTextInZones - SUCCESS in zone1: found=" . result[1].id . " at " . result[1].x . "," . result[1].y . " searchTime=" . SearchStats.searchTimeMs . "ms")
        return result
    }

    ; Try second zone if provided
    if (zone2 != "" && IsObject(zone2)) {
        if (result := FindText(, , zone2.x1, zone2.y1, zone2.x2, zone2.y2, err1, err2, target)) {
            SearchStats.searchTimeMs := A_TickCount - startTime
            SearchStats.foundInZone := "zone2"
            ; Log all successful results
            WriteLog("DEBUG: FindTextInZones - SUCCESS in zone2: found=" . result[1].id . " at " . result[1].x . "," . result[1].y . " searchTime=" . SearchStats.searchTimeMs . "ms")
            return result
        }
    }

    SearchStats.searchTimeMs := A_TickCount - startTime
    SearchStats.foundInZone := "none"
    if (verbose)
        WriteLog("VERBOSE: FindTextInZones - NOT FOUND: target=" . targetId . " searchTime=" . SearchStats.searchTimeMs . "ms")
    return 0
}

; Set coordinate mode to window coordinates for unified coordinate system
CoordMode("Mouse", "Window")
CoordMode("Pixel", "Window")

; Upchieve Waiting Student Detector
; Hotkeys: Ctrl+Shift+Q to quit, Ctrl+Shift+H to pause/resume, Ctrl+Shift+A to end session

TargetWindow := "UPchieve"
IsActive := false
SoundTimerFunc := ""
LiveMode := false

; Session state management
WAITING_FOR_STUDENT := "WAITING_FOR_STUDENT"
IN_SESSION := "IN_SESSION" 
PAUSED := "PAUSED"
SessionState := WAITING_FOR_STUDENT

; Session tracking variables
LastStudentName := ""
LastStudentTopic := ""
LastRawStudentName := ""  ; Original OCR result for student name
LastStudentTopic := ""  ; Subject from pattern matching
SessionStartTime := ""
SessionEndTime := ""

; Scan timing variables
ScanTimes := []
ScanCount := 0

; Session end detection timing
lastSessionEndCheck := 0

; Search statistics tracking
SearchStats := {
    searchTimeMs: 0,
    foundInZone: "none"
}

; Function to play notification sound
PlayNotificationSound() {
    SoundBeep(800, 500)  ; 800Hz beep for 500ms
}

; Image targets
PageTarget1 := "|<WaitingStudents>*132$271.0000000000000s00007U00000000000000000000000000000000000001y00007s00000000000000000000000000000000000000zU0003w00000000000000000000000001y00z00TU0000Tk0Q01y00000000000000Dw000k000000z00TU0DU0000Ds0y00z00000000000000zzk03s000000DU0Dk07k00003s0T00TU00000000C0001zzy01w0000007k0Ds03s00000s0DU07U00000000DU001zzzU0y0000003w07y03w00000007k00000000000Dk001zUTs0T0000000y03z01w00000003s00000000000Ds000z03y0DU000000T01zU0y00000001w000000000007U000z00T07k000000DU1vk0T03z007kTzzUz0T1z000zr0000T00D1zzy3w07k7s0ww0D07zw03sDzzkTUDXzs01zzU000DU030zzz1y03s1w0SS0DU7zz01w7zzsDk7nzy03zzk0007k000TzzUz01w0y0DD07k7zzk0y3zzw7s3vzzU3zzw0003s000DzzkTU0y0T0DbU3s7w7w0T03s03w1zsTk1z1z0001y0000DU0Dk0T07k7Xs1s7s1y0DU1w01y0zk3w1y0TU000zk0007k07s0DU3s3kw1w3s0T07k0y00z0Tk1y0z07k000DzU003s03w07k1w1sS0y0Q0DU3s0T00TUDk0T0T03w0007zzU01w01y03s0y0wD0S0007k1w0DU0Dk7s0DUDU1y0001zzy00y00z01w0DUw7kD0003s0y07k07s3w07k7k0z0000DzzU0T00TU0y07kS1sDU007w0T03s03w1y03s3w0T00001zzw0DU0Dk0T03sD0w7U01zy0DU1w01y0z01w0zUzU00003zz07k07s0DU0w7US3k07zz07k0y00z0TU0y0TzzU000003zU3s03w07k0T7U7Vs0DzzU3s0T00TUDk0T07zzU000000Tk1w01y03s0DXk3lw0Dy7k1w0DU0Dk7s0DU1zzU0000003w0y00z01w07ls1sw0Dk3s0y07k07s3w07k1zz00000001y0T00TU0y01sw0wS0Dk1w0T03s03w1y03s1s000000k00z0DU0Dk0T00yw0DD07k0y0DU1w01y0z01w1s000000w00TU7k07s0TU0TS07j03s0T07k0y00z0TU0y0w000000z00DU3s01w0Dk07j03rU1w0TU3s0T00TUDk0T0S000000Tk0Dk1y00z0Ds03z01zk0zVzs1w0DksDk7s0DUDU000007y0Tk0zVUTkTw01zU0Ts0TzzzUy07zw7s3w07k7zzw0001zzzk0Dzk7zzy00Tk0Ds07zyzkT01zy3w1y03s1zzzU000Tzzk07zs3zzD00Ds07w01zwDsDU0Tz1y0z01w0Tzzs0003zzU01zw0Tz7U07s03y00Ds3s7k03w0z0TU0y0Dzzw0000Dz000Ds03y3k0000000000000000000000000T00y00000000000000000000000000000000000000000D00DU000000000000000E" 
PageTarget2 := "|<WaitingStudents>*131$277.00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000007U0000S0000000000000000000000000000000000000007s0000TU000000000000000000000000000000000000003y0000Dk000000000000000000000000007k03w01y00001z01k07s00000000000000zk00300000003w01y00y00000zU3s03w00000000000003zz00DU0000000y00z00T00000TU1w01y000000000s0007zzs07k0000000T00zU0DU00007U0y00S000000001w0007zzy03s0000000DU0Ts0DU0000000T000000000000z0007y1zU1w00000007s0Dw07k0000000DU00000000000zU003w0Ds0y00000001w07y03s00000007k00000000000S0003w01w0T00000000y07j01w0Dw00T1zzy3s1w7w003zQ0001w00w7zzsDU0T00T03nk1w0Tzk0DUzzz1w0yDzU07zy0000y00A3zzw7k0DU07k1ts0y0Tzw07kTzzUy0TDzs0Dzz0000T0001zzy3s07k03s0ww0T0Tzz03sDzzkT0Djzy0Dzzk000DU000zzz1w03s01w0yS0D0TkTU1w0DU0DU7zVz07w7w0007s0000y00y01w00S0SDUDUTU7s0y07k07k3z0Dk7s1y0003z0000T00T00y00DUD3k7kDU1w0T03s03s1z07s3s0T0001zy000DU0DU0T007k7Vs3s1U0y0DU1w01w0z01w1w0Dk000Tzy007k07k0DU03s7kw1s000T07k0y00y0TU0y0y07s0007zzk03s03s07k40w3kT1w000DU3s0T00T0Dk0T0T03w0000zzy01w01w03s20T1s7Uy000Tk1w0DU0DU7k0DUDk3w00007zzk0y00y01w10DUw3kS007zs0y07k07k3s07k3y3y00000Dzs0T00T00y0U3kw1sD00Tzw0T03s03s1w03s1zzy000000Dy0DU0DU0T0E1sS0yDU0zzy0DU1w01w0y01w0Tzy0000001z07k07k0DU80yD0D7k0zsT07k0y00y0T00y07zy0000000Dk3s03s07k40T7U7Xk0z0DU3s0T00T0DU0T0Dzw00000007s1w01w03s207bU3ls0z07k1w0DU0DU7k0DU7U000003003w0y00y01w103nk0xw0T03s0y07k07k3s07k7U000003U01w0T00TU1y001xs0Sw0DU1w0T03s03s1w03s3k000003s00y0DU07k0z000Sw0DS07k3y0DU1w01w0y01w1s000001z00z07k03w0zU00Dw07z03w7zU7k0z3Uy0T00y0y000000Ts1z03y61z1zk007y01zU1zzzy3s0TzkT0DU0T0Tzzk0007zzz00zz0Tzzs003z00zU0Tzvz1w07zsDU7k0DU7zzy0001zzz00TzUDzww000zU0Tk07zkzUy01zw7k3s07k1zzz0000Dzy007zk1zwS000TU0Ds00zUDUT00Dk3s1w03s0zzzk0000zw000zU0DsD000000000000000000000000001w03s000000000000000000000000000000000000000000s00y000000000000000000000000000000000000000000w00T000000000000000000000000000000000000000000S00D000000000000000000000000000000000000000000DU0DU000000000000000000000000000000000000000007y0Tk000000000000000000000000000000000000000001zzzk00000000000000004"
PageTarget3 := "|<WaitingStudents>*131$133.0000000000000000000000000000000000000000000000000000000000000000000D000000000000000000000Dk000000000000000000007s000000000000000000003w00000000000000Ts001U1y00000000000001zzU07k0z000000000Q0003zzw03s0D000000000y0003zzz01w00000000000TU003z0zk0y00000000000Tk001y07w0T00000000000D0001y00y0DU1w0y3y001zi0000y00S3zzky0T7zk03zz0000T0061zzsT0Dbzw07zzU000DU000zzwDU7rzz07zzs0007k000Tzy7k3zkzU3y3y0003w0000T03s1zU7s3w0z0001zU000DU1w0zU3w1w0DU000zz0007k0y0TU0y0y07s000Dzz003s0T0Dk0T0T03w0003zzs01w0DU7s0DUDU1y0000Tzz00y07k3s07k7s1y00003zzs0T03s1w03s1z1z000007zw0DUE"
PageTarget4 := "|<WaitingStudents>*133$143.000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000S00000000000000000000001y00000000000000000000003w00000000000000000000007s00000000000000zk003000Dk0000000000000Dzw00y000TU00000000C0001zzy01w000S000000000y0007zzy03s0000000000003w000Ts7y07k000000000000Ds000z03y0DU000000000000S0003w01w0T000Dk7kTk00Dxk0007k03kTzzUsTUDXzs01zzU000DU030zzz1kz0TDzs0Dzz0000T0001zzy3Vy0yzzs0zzz0000y0003zzw73w1zsTk1z1z0001y0000DU0C7s3z0Dk7s1y0003z0000T00QDk7w0TUDk1w0003zs000y00sTUDk0T0T03w0007zzU01w01kz0TU0y0y07s0007zzs03s03Vy0z01w1w0Dk0003zzs07k073w1y03s3w0T00001zzw0DU0C7s3w07k3y3y00000Dzw0T00QDk7s0DU7zzs000000zs0y00sTUDk0T07zzU000000Tk1w01kz0TU0y07zy0000000Dk3s03k"

PageTarget := PageTarget4

WaitingTarget1 := "|<Waiting>*150$65.00000000000000000s0000000003k000000000DU000000E01z0000003U0Di000000T00QQ006C07s000s00Bw0z0001k00TU7s0003U00w0y00007001k3k0000C003U600000Q0070D00000s00A0DU0001k00M07k0003U00k03s0007001U01y000C003000z000Q006000S000s00A000A001k00M0000003U00k00000000000E"
WaitingTarget2 := "|<Waiting>*151$86.00000000000000000000600000000000003U0000000000003s0000000000U03y0000000000s01tU000000000y00QM00CTUz000z0006003jwTs00y0001U00z7i700y0000M00DUT0s1y00006003k7UC0y00001U00s1k1UC00000M00C0Q0M3k00006003U7060T00001U00s1k1U1y0000M00C0Q0M07s0006003U70600TU001U00s1k1U00y000M00C0Q0M003U006003U7060008001U00s1k1U000000M00C0Q0M00000000000000000000000000000U"
WaitingTarget3 := "|<Waiting>*152$38.000001k00000w00000T00400Tk0700TQ07k0770Dk001kDk000QDk0007DU0001rU0000RU00007S00001ns0000QDU00070y0001k3w000Q0Dk00700w001k03000Q0000070000008"

WaitingTarget := WaitingTarget3 

; Using "New" is a workaround for the first two targets not being found for unknown reasons
UpgradeTarget := "|<Upgrade>*196$93.zzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzwTwQ03zk3y03zzzzXzXU07w0Dk07zzzwTwQDUz1Uy7UTzzzXzXVz3kz3kz3zzzwTwQDwQDwS7wTzzzXzXVzVVzVkzVzzzwTwQDwATzy7wDzzzXzXVzXXzzkzXzzzwTwQDsQTzy7sTzzzXzXVy3Xzzky3zzzwTwQ00wT0C00zzzzXzXU0TXs1k0TzzzwTwQDzwTwC7XzzzzXzXVzzXzVkwDzzzwDwQDzwDwC7lzzzzVz3VzzlzVky7zzzy7sQDzy7wC7sTzzzkQ7VzzsC1kz3zzzz01wDzzU0y7wDzzzy0zVzzz0Dkzkzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzw"
               . "|<UpgradeGray2Two_wide>*230$137.00M001zzzzzzzzzzzzzzzzy00k007zzzzzzzzzzzzzzzzw00U00Dzzzzzzzzzzzzzzzzs01U00Tzzzzzzztzls0TzUTk03000zzzzzzzznzXk0Dw0DU02003zzzzzzzzbz7bwDkwD004007zzzzzzzzDyDDyD7yS00800DzzzzzzzyTwSTwSDwQ00M00Tzzzzzzzwzswzwwzws00k00zzzzzzzztzltztlzzk01U01zzzzzzzznzXnzXXzzU03003zzzzzzzzbz7bz77zz006007zzzzzzzzDyDDwSDzy00A00DzzzzzzzyTwS01wT0Q00M00Tzzzzzzzwzsw07sy0s00k00zzzzzzzztzltzzlztk01U01zzzzzzzznzXnzzXznU03003zzzzzzzzbz7bzzbzb004007zzzzzzzzDyTDzz7zC00800DzzzzzzzyDsyTzz7yQ00E00TzzzzzzzyDXwzzy7ks01U00Tzzzzzzzy0Dtzzy03k03000zzzzzzzzz0znzzz0TU04001zzzzzzzzzzzzzzzzz00M003zzzzzzzzzzzzzzzzz"
               . "|<New>*134$76.7U07U00000000T00S000000001y01s000000007s07U00000000Tk0S000000001zU1s000000007y07U00000000Tw0S01y0Q0Q0Fvk1s0Ty1s1s17bU7U3zw7U7U4SD0S0S3sC0y0Fsw1s3k7Us3w37Vs7US0C3kDkAS7kS1s0w71r0lsD1s703kQ7Q37US7UQ071kQsQS1wS3zzw7VXVls3lsDzzkCCC77U7bUzzz0ssQQS0TS3k003XVnVs0xsD000DQ7C7U1zUQ000RkCsS07y1s001z0vVs0Ds7U007s3w7U0zUD0C0DU7kS01y0z1s0y0T1s03s1zzU3k1s7U0DU1zs0D07US00S01y00Q0C00000000000000000000000002"
 
EndSessionTarget :="|<EndSession>*194$193.00C0000000000000000000000000000000C0000000000000000000000000000000C0000000000000000000000000000000C0000000000000000000000000000000C000000000000000000000000000000060000000000000000000000000000000600000000000000000000000000000007000000000000000000000000000000030000000000000000000000000000000300000000000000000000000000000003U0000000000000000000000000000001U0000000000000000000000000000000k0000000000000000000000000000000k0000000000000000000000000000000M0000000000000000000000000000000Q0000000000000000000000000000000A000000000000000000000000000000060000000000000000S0000000000000070000000000000000D00000000000000300000000zzw000007U007w0000000001U0000000Tzy000003k00DzU000000000k0000000Dzz000001s00Dzs000000000s00000007U0000000w00D0S000000000M00000003k0000000S00D07000000000A00000001s00STU0zD007U103w03w0Ds600000000w00DTs0zzU03k007zU7zUTz300000000S007zy0zzk01w007zs7zsDzlU0000000D003w7Uw3s00zU07US7UQD1sk00000007zw1w3kS0w00DzU3U73k470MM00000003zy0w0sS0S003zw3k3Vs03k0A00000001zz0S0QD0D000TzVzzkzU1y0600000000w00D0C7U7U000zkzzsDz0Tw300000000S007U73k3k0001wTzw1zk3zVU0000000D003k3Vs1s0000SD0007w0Dsk00000007U01s1kw0w0080D7U000D00wQ00000003k00w0sD0S00C07Vs20U7V0C600000001s00S0Q7UT007k7Uw3ks3lkD300000000zzwD0C1zzU01zzUDzkTzkzzVU0000000Tzy7U70Txk00TzU3zk7zkDzUs0000000Dzz3k3U7ss003z00Tk0zU1z0A0000000000000000000000000000000600000000000000000000000000000003U0000000000000000000000000000000k0000000000000000000000000000000M000000000000000000000000000000060000000000000000000000000000000300000000000000000000000000000001k0000000000000000000000000000000M0000000000000000000000000000000600000000000000000000000000000003U0000000000000000000000000000000k0000000000000000000000000000000A0000000000000000000000000000000700000000000000000000000000000001k0000000000000000000000000000000Q0000000000000000000000000000000700000000000000000000000000000001k0000000000000000000000000000000Q0000000000000000000000000000000700000000000000000000000000000001s0000000000000000000000000000E"
FinishTarget :="|<Finish>*225$127.01000000000000000000001U00000000000000000001U00000000000000000000U00000000000000000000k00000000000000000000E00000000000000000000E00000000000000000000M00000000000000000000800000000000000000000400000000000000000000400000000000000000000200000000000000000000300000000000000000000100000000000T0000w0000U0000000000DU000z0000E0000000Dzz7k000TU000M00000007zzXk0007U000800000003zzk000000000400000001s00000000000200000000w00000000000100000000S00D1tz0S0zk0U0000000D007UzzkD0zy0k00000007U03kTzw7Uzz0M00000003k01sDky3ky7kA00000001zz0w7kD1sS1k600000000zzkS3s7kwDU0300000000TzsD1s3sS7y01U0000000D007Uw1wD1zs0E00000007U03kS0y7UTz0800000003k01sD0T3k1zk400000001s00w7UDVs03s200000000w00S3k7kw60w100000000S00D1s3sS7Uy0k0000000D007Uw1wD3zz0800000007U03kS0y7Uzz0400000003k01sD0T3k7y02000000000000000000001U00000000000000000000E000000000000000000008000000000000000000002000000000000000000001000000000000000000000k0000000000000000000E"

StudentHeaderTarget := "|<Student>*146$71.00000000000000000000001w3z00k000003sTzUDU000007nzzkT000000Djzzky000000TTUT1w000000yy0QTznw7k3txw0EzzbsDUTvvy01zzDkT1zzrzk3zyTUy3zzjzw0y0z1wDkzDzy1w1y3sT0yDzy3s3w7ky1w3zw7k7sDVw3s0TsDUDkT3s7m0DkT0TUy7kDa0DUy0z1wDUTT0z1w1y7sTVzzzy3zlzzkzzxzzs7zXzzUzztzzU7z3zD0znkTs03w3wS0T7U00000000000000000000001"
HelpHeaderTarget := "|<HelpHeader>*147$71.0000000000000000000z0001y0T0001y0003w0y0003w0007s1w0007s000Dk3s000Dk000TU7k000TU000z0DU3w0z1sy1y0T0Ty1y3nz3w0y1zy3w7jz7s1w7zy7sDzyDzzsTVyDkTVyTzzky1wTUy3wzzzVzzsz1w3tzzz3zzly3s7nw0y7zzXw7kDbs1wDU07sDUTDk3sT00DkT1yTU7kz1sTUz3wz0DUzzkztzzly0T0zzUznzzXw0y0zy1z7ry7s1w0Tk1yDbk000000000T00000000000y01"
WaitTimeHeaderTarget:="|<WaitTime>*148$97.000000000000000000000000D0000000C0z0T000Dk3007zzzUTUDU007sDU03zzzkDkDk003w7k01zzzs7s7s000w3s00zzzw3y3s00001w000DUS3z1w3y0Tbzw007kDVzUy7zkDnzy003s7kzky7zw7tzz001w3sQsT3zz3wzzU00y1wSSDXsTVy3s000T0yDD7UQ7kz1w000DUDbbXk07sTUy0007k7nnns0zwDkT0003s3tkxw3zy7sDU001w0xsSw3wT3w7k000y0TwDy3sDVy3s000T0Dy7z1wDkz1y000DU7y1z0zzyTUzw007k1z0zUTzzDkTy003s0zUTk7zTbs7z001w0TkDs1y7nw0z000y000000000000000000000000000000000E"

SessionEndedTarget := "<SessionEnded>*195$237.zzzzzzzzzzzzs7zzzzzzzzzzzzzzzzsDzzzzz1zzs0zzzzzzzzzz0zzzzzzzzzzzzzzzzz1zzzzzsDzw01zzzzzzzzzs7zzzzzzzzzzzzzzzzsDzzzzz1zz007zzzzzzzzzVzzzzzzzzzzzzzzzzz1zzzzzsDzk30TzzzzzzzzzzzzzzzzzzzzzzzzzzsDzzzzz1zy3y3zzzzzzzzzzzzzzzzzzzzzzzzzzz1zzzzzsDzkTszk3zk3zU7wDw0zkk7zzy0Tks7zUMDw1zw31zy3zjw07s07k0DVy01y40Tzz01y00Tk01y03y00DzkDzy00S00Q00wDU07k01zzk07k01w00DU0DU01zy07zkA3kA3UM7Vw30y0kDzy1US0EDU81s20w30Dzk03w7sC3sw7lwD0y3kD1zzUz3kD0s7kD1w70y1zz00DUz1kTjUzTVsDkS3s7zw7sC3w71y1kTksDkDzy00Q00C0Dw0TwD1z3kTUzzU01kTUsDsC0071z1zzw03U01s0Dk0TVsDsC3w7zw00C3w71z1k00sDsDzzz0Q00DU0z01wD1z1kTUzzU01kTUsDsC0071z1zzzy1Uzzz03y07VsDsS3w7zw7zy3w71z1kTzsDsDztzkA7zzzUTz0wD1y3kTUzzUzzkTUsDkC3zz1y1zy7y3UT3tz1ny3Vs7kS3w7zw3sy3w70y1sDVs7kDzU70S0UC1UQ30wDUM7kTUzzkA3kTUw10D0M7UM1zy007s03k03U07Vw00y3w7zy00S3w7U01w01w00Dzs01zU0z00y01wDk0DkTUzzs07kTUy08Dk0Tk11zzk0zy0Tw0Ts0zVzU7y3w7zzk3y3w7w31zU7zUMDzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzU" .
                      "|<SessionEnded>*194$133.zzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzz3zzzzzzzzzzzzzzzzy3zzz0zzzzzzzzzzzzzzzzz1zzzUTzzzzzzzzzzzzzzzzUzzzkDzzzzzzzzzzzzzzzzkTzzwDzzzzzzzzzzzzzzzzsDzzzzzzzzzzzzzzzzzzzzw7zzzzzzzzzzzzzzzzzzzzy3w0zVzU7y60zzzk3y70zw31s07kz00z20DzzU0T00Ds00s01sT00DU03zzU0DU03s00Q30wDUM7k61zzkA3k21w10C3sy7UT1s7UzzkTVs7UQ3s71yz3kTUw7kDzsDkQ7sC3w3U3zVsDsS3w7zw00C3w71z1s0Dkw7w71y3zy0071y3UzUy03sS3y3Uz1zz003Uz1kTkTk0wD1z3kTUzzUzzkTUsDsDzUS7Uz1sDkTzkTzsDkQ7s7bw73kDUw7sDzs7lw7sC1w3UM7Vw30y3w7zy1US3w7U81k03ky00T1y3zz00D1y3k00w03sTU0TUz1zzk0DUz1w0ET07wDw0zkTUzzy0TkTUzUMDzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzw"


PencilTipTarget :="|<PencilTip>**50$69.000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001zs000000007w3y0000000DU00T0000007U000S000003U0000Q00001k00k00s0000Q00D003U000C001w0070003U00Nk00Q000k0076000k00A001ks003003000A3U00A00k003UA000k0A000ryk00303000Dzz000A0M001k0Q001U6000Q01U0061U00700C000MA000k00s0033000C003U00AE003U00A000a000s001k006U0060007000I001k000Q003U00Q0003U00M0070000C001000k0000s00800C00003001003U0000Q00000s00001k0000600000700001k00000M0000Q000003U0007000000C0000s000000s000C0M0k1U3U001k7UD0C0Q000D0y1w3s7U001wCsRkvVw000BnXb7CCTU001bsDkTUzQ000Ay0w1s3nU001XU3U70CQ000A8080E0XU001U000000Q04"

SubjectTargets :=  
    "|<7th Grade Math>*126$48.Tzw00300Tzw3030000Q3030000s3030000k3030001Uzz37k03Uzz3Tw030303wS070303kC060303U70C0303U70A0303U70Q0303070Q0303070M0303070M0303070s0303070s0303070s03X3070s03z3070s00y307U" .
    "|<8th grade math>*128$48.000003003y000300Dz030300C7U30300Q1k30300M1k30300M1kzz37kQ1kzz3TwQ1k703wSD7U303kC7z0303U7Dz0303U7S3k303U7s0k30307s0s30307k0s30307k0s30307s0s30307s1s30307S3k3X307DzU3z3073y00y307U" .
    "|<9th grade math>*129$49.000001k0000000s00TU000Q00zw0A0C00wD060700w1U303U0Q0s1U1k0C0A7zkty7073zsRzXU3UA0Dltk3k607UCw1s303U7D3g1U1k3Xzq0k0s0kTX0M0Q0M01UA0C0A01k60706E0s303U3Q0M1U1k1j0Q0k0s0nkw0QMQ0Mzw07wC0A7s01w707" .
    "|<Pre-algebra>*128$45.zw000007zk00000kD0000060Q00000k1U000060C6D0TUk1krsDz60C7k3kwk1Uw0Q3a0Q7070CkD0s0k1rzk70606zw0s0zzq00707zyk00s0k060070600k00s0s0600703UCk00s0S3a00701zsk00s03y4" .
    "|<Algebra>*130$47.0D01k0000S03U0001w0700003w0C001k6M0Q007UQs0s0Tw0tk1k3zk1VU3U73k73U70Q3UA70C0k3Us70Q1U71kC0s30C30A1k70sDzw3UD3kTzs70Dz1k0sC0Ts3U1kQ1U0601Us300Q03Us700s071yDznU071wDzk00000k1k0000301U000060300000C0D" .
    "|<Statistics>*129$40.1z00000Tz07003kT0Q00C0Q1k01k0s7007003zw3Q00Dzkxk00707Xk00Q0QDy01k0UDz070007z0Q0001w1k0401s701k03UQ0S8061k1nU0s70C703UQ0sDUw0sVkTzU3z7kTs07k7U" .
    "|<Integrated math>*131$39.s000007000060s0000k7000060s0000k70lw0zys6zs7zr0z7U60s7UQ0k70s1k60s70C0k70s1k60s60C0k70k1k60s60C0k70k1k60s60C0k70k1k60s60C0sr0k1k3ys60C0DY" .
    "|<Science>*131$50.00007001k0003k00Tk0D0w007y03k7001zU0w0000Ts0T00007r07k0001xk1g1k1wTA0v0Q1zrnUAk70wDws7A1kC0z61n0Q70DlkMk71k1wACA1kM0T3XX0Q607kskk71U1w6QA1kM0T1a30Q707kRUk71k3w3sA1kC0z0w30Q3kzk70k70Txw1kA1k1yS" 
 SubjectTargets_2 :=  
    "|<CSA>*138$23.00000D000S000y003w006M00Qs00tk01Vk073U0C300s701kC030A0Dzw0Tzs1k0s3U1k601UQ03Us071U0700000000U" .
    "|<CSP>*143$18.000000DzUDzkC1sC0QC0QC0CC0CC0CC0QC0QC1sDzkDzUC00C00C00C00C00C00C00C00U"

BlockedTargets :=
    "|<Chukwudi>*130$161.07w0A000001k0A0000000001Uw00zy0M000003U0M00000000030k03sT0k00000700k0000000006000D0C1U00000C01U000000000A000w0C3000000Q030000000000M001k0E6DU3U30s1rk3U730707skA03000Bzk7061k7DUD0Q60C0TtUM0C000TXkC0A3UQP0S0sA0Q1sz0k0Q000w3UQ0M71kr0y1kM0s70S1U0s001k3Us0kC71i3g30k1kQ0Q301k003U71k1UQQ3A6MC1U3Us0s603U0070C3U30tk6QAsQ3071k1kA07000A0Q7061rkAsskk60C3U1UM0C000M0sC0A3zkMlVXUA0Q7030k0A000k1kQ0M7nUln3a0M0sC0C1U0Q071U3Us0kD3VXi3A0k1kQ0Q300w0C3071k3UQ3X3M6s1k3Us0s600w0s60C1kD0s767kDU3UD0s3kA00y7UA0Q3ky1k7ADUD03Vy0wTUM00zy0M0s3zg3U7MC0S07zg0zv0k00Tk0k1k1wM70CkQ0s03wM0z61U00000000000001U0000000000000000000000000300000000000000000000000000600000000000000000000000000A0000000000001" .
    "|<Camila>*130$106.000000000000000000000000000000s60000000000000003kM00003w000000000D1U0000zw000000000s60000DVw0000000000M0001s1k0000000001U000703U00000000060000s000TU37kDU3UM0TU3U007z0BznzU61U3zUQ000wC0y7yD0M60QD1k0070Q3kDUQ3UM3UA700081kC0Q0s61U40sQ000070s1k3UM6003Vk0000Q3U70C1UM00S70001zkA0Q0s61U0zsQ000Tz0k1k3UM60DzUk003kQ3070C1UM1sC3U0MQ1kC0Q0s61UC0s703VU70k1k3UM60k3US0Q70w3070C1UM30S0y7kQ7kA0Q0s61kC3s0zw0zvks1k3UM7sTxk0z00y73070C1U7Uz70000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000002"

; Debug log function
WriteLog(message) {
    logFile := "debug_log.txt"
    timestamp := FormatTime(A_Now, "yyyy-MM-dd HH:mm:ss") . "." . Format("{:03d}", A_MSec)
    FileAppend timestamp . " - " . message . "`n", logFile
}

; App log function for session data in CSV format
WriteAppLog(message) {
    logFile := "upchieve_app.log"
    
    ; Create header if file doesn't exist
    if (!FileExist(logFile)) {
        header := "Seq,,RTime,Time,Until,W,Name,Grd,Fav,Assgn,Subject,Topic,Math,Duration,Initial response,Serious question,Left abruptly,Stopped resp,Good progress,Last msg,Comments" . "`n"
        FileAppend header, logFile
    }
    
    FileAppend message . "`n", logFile
}

; Simple function to convert FindText center coordinates to upper-left coordinates
; Simplified for window coordinate system
GetUpperLeft(result) {
    ; Extract upper-left coordinates directly from FindText result object
    return {x: result[1].1, y: result[1].2}
}

; Check for upgrade popup and click it if found
; Returns true if popup was found and clicked, false otherwise
CheckUpgradePopups() {
    global UpgradeTarget, targetWindowID

    if (UpgradeTarget == "") {
        return false
    }
    Sleep 5000
    WinGetClientPos(, , &winWidth, &winHeight, targetWindowID)
    upgradeResult := FindText(,,winWidth/3, winHeight/3, winWidth*2/3, winHeight*2/3,0.1,0.1, UpgradeTarget)
    
    if (upgradeResult) {
        WinActivate("ahk_id " . targetWindowID)
        ToolTip "Found upgrade popup! Clicking...", 10, 10
        click_x := upgradeResult[1].x 
        click_y := upgradeResult[1].y
        if upgradeResult[1].id = "New" {
            click_x := upgradeResult[1].x + 480
            click_y := upgradeResult[1].y + 200
        }
        Click upgradeResult[1].x, upgradeResult[1].y
        WriteLog("Upgrade button clicked at " . click_x . "," . click_y)
;        MsgBox("Upgrade button clicked at " . click_x . "," . click_y)
        Sleep 3000  ; Pause to allow reloading page
        ToolTip ""
        return true
    } 
    return false
}

; Find all header targets and store their positions for search zone calculations
; This function will not return until ALL headers are found or user cancels
FindHeaders() {
    global StudentHeaderTarget, HelpHeaderTarget, WaitTimeHeaderTarget, targetWindowID

    while (true) {
        ; Initialize header positions (will be empty if not found)
        global studentHeaderPos := {x: 0, y: 0, found: false}
        global subjectHeaderPos := {x: 0, y: 0, found: false}
        global waitTimeHeaderPos := {x: 0, y: 0, found: false}

        ; Get window client area dimensions for boundary checking
        WinGetClientPos(, , &winWidth, &winHeight, targetWindowID)

        ; Define search zones for Student Header
        studentZone1 := SearchZone(600, 1150, 900, 1250)
        studentZone2 := SearchZone(0, 150, 0, 2000, 1800, 0)   ; Wider fallback zone

        ; Search for Student Header
        if (result := FindTextInZones(StudentHeaderTarget, studentZone1, studentZone2)) {
            upperLeft := GetUpperLeft(result)
            studentHeaderPos := {x: upperLeft.x, y: upperLeft.y, found: true}
        }

        ; Define search zones for Subject Header (position relative to Student header if found)
        if (studentHeaderPos.found) {
            subjectZone1 := SearchZone(studentHeaderPos.x + 200, studentHeaderPos.y - 10, 0, 0, 200, 50)
        } else {
            subjectZone1 := SearchZone(600, 600, 1100, 1400)
        }
        subjectZone2 := SearchZone(0, 150, 2000, 2000)  ; Wider fallback zone

        ; Search for Subject Header (was Help Header)
        if (result := FindTextInZones(HelpHeaderTarget, subjectZone1, subjectZone2)) {
            upperLeft := GetUpperLeft(result)
            subjectHeaderPos := {x: upperLeft.x, y: upperLeft.y, found: true}
        }

        ; Define search zones for Wait Time Header (position relative to Student header if found)
        if (studentHeaderPos.found) {
            waitTimeZone1 := SearchZone(studentHeaderPos.x + 500, studentHeaderPos.y - 10, 0, 0, 300, 50)
        } else {
            waitTimeZone1 := SearchZone(600, 600, 1100, 1400)
        }
        waitTimeZone2 := SearchZone(100, 150, 2000, 2000)  ; Wider fallback zone

        ; Search for Wait Time Header
        if (result := FindTextInZones(WaitTimeHeaderTarget, waitTimeZone1, waitTimeZone2, 0.15, 0.10)) {
            upperLeft := GetUpperLeft(result)
            waitTimeHeaderPos := {x: upperLeft.x, y: upperLeft.y, found: true}
        }

        ; Check if all headers found
        if (studentHeaderPos.found && subjectHeaderPos.found && waitTimeHeaderPos.found) {
            ; All headers found - return successfully
            WriteLog("All 3 headers found")
            return
        } else {
            ; Missing headers - show simple message box
            result := MsgBox("Missing column headers. Please adjust the browser window to ensure all column headers are visible, then click OK to retry.", "Missing Column Headers", "1 4096")  ; OK/Cancel
            if (result = "Cancel") {
                CleanExit()
            }
            ; If OK clicked, the loop will continue and retry
        }
    }
}

/* ; Load blocked names from block_names.txt
LoadBlockedNames() {
    blockedNames := []
    blockFile := "block_names.txt"
    
    ; Check if file exists
    if (!FileExist(blockFile)) {
        ; WriteLog("block_names.txt not found - no names will be blocked")
        return blockedNames
    }
    
    ; Read file line by line
    try {
        fileContent := FileRead(blockFile)
        lines := StrSplit(fileContent, "`n", "`r")
        
        for index, line in lines {
            trimmedName := Trim(line)
            if (trimmedName != "" && InStr(trimmedName, ";") != 1) {  ; Skip empty lines and comments
                blockedNames.Push(trimmedName)
            }
        }
        
        ; WriteLog("Loaded " . blockedNames.Length . " blocked names from " . blockFile)
    } catch Error as e {
        ; WriteLog("ERROR: Failed to read " . blockFile . " - " . e.message)
    }
    
    return blockedNames
}

; Check if student name is in blocked list
IsNameBlocked(studentName, blockedNames) {
    ; Normalize student name: lowercase, remove punctuation and extra spaces
    normalizedStudentName := StrReplace(StrReplace(StrReplace(StrLower(Trim(studentName)), "-", ""), "'", ""), " ", "")

    for index, blockedName in blockedNames {
        ; Normalize blocked name: lowercase, remove punctuation and extra spaces
        normalizedBlockedName := StrReplace(StrReplace(StrReplace(StrLower(Trim(blockedName)), "-", ""), "'", ""), " ", "")
        if (normalizedStudentName == normalizedBlockedName) {
            return true
        }
    }
    return false
}
*/

; Check for blocked name patterns using exact OCR search zone
CheckBlockedNamePatterns() {
    global studentHeaderPos, targetWindowID, BlockedTargets

    ; Use precise header-based positioning relative to StudentHeader middle coordinates
    blockingZone := SearchZone(studentHeaderPos.x - 5, studentHeaderPos.y + 95, 0, 0, 200, 35)

    ; Search for blocked patterns in calculated zone
    if (result := FindTextInZones(BlockedTargets, blockingZone,, 0.15, 0.10)) {
        ; Found a blocked name pattern
        blockedName := result[1].id  ; Get the pattern name (e.g. "Chukwudi", "Camila")
        WriteLog("BLOCKED: " . blockedName)

        ; Show message box notification
        MsgBox("Blocked student detected: " . blockedName, "Student Blocked", "OK Iconi 4096")

        return {blocked: true, name: blockedName}
    }

    ; No blocked patterns found
    return {blocked: false, name: ""}
}

; Apply only known corrections from database without user prompts
ApplyKnownCorrections(ocrResult) {
    global correctionDatabase, knownStudents
    
    cleanOCR := Trim(ocrResult)
    if (cleanOCR == "") {
        return ""
    }
    
    ; Check if we have a known correction for this exact OCR result
    if (correctionDatabase.Has(cleanOCR)) {
        return correctionDatabase[cleanOCR]
    }
    if (correctionDatabase.Has(ocrResult)) {
        return correctionDatabase[ocrResult]
    }
    
    ; Check for exact match in known students (case-insensitive)
    for student in knownStudents {
        if (StrLower(cleanOCR) == StrLower(student)) {
            return student  ; Return with proper casing
        }
    }
    
    ; Return cleaned OCR result if no corrections found
    return cleanOCR
}



; Extract topic using header-based positioning
; Uses header positions with standard row offsets
ExtractTopic() {
    global subjectHeaderPos, SubjectTargets, SubjectTargets_2, targetWindowID

    ; Define primary zone: x-5, y+95, 150x30 from SubjectHeader upper-left
    primaryZone := SearchZone(subjectHeaderPos.x - 5, subjectHeaderPos.y + 95, 0, 0, 150, 30)

    ; Try primary zone with SubjectTargets
    if (result := FindTextInZones(SubjectTargets, primaryZone)) {
        WriteLog("DEBUG: Subject: found=" . result[1].id . " searchTime=" . SearchStats.searchTimeMs . "ms foundInZone=" . SearchStats.foundInZone)
        return result[1].id
    }

    ; Define secondary zone: x+65, y+95, 35x30 from SubjectHeader upper-left
    secondaryZone := SearchZone(subjectHeaderPos.x + 65, subjectHeaderPos.y + 95, 0, 0, 35, 30)

    ; Try secondary zone with SubjectTargets_2
    if (result := FindTextInZones(SubjectTargets_2, secondaryZone)) {
        WriteLog("DEBUG: Secondary Subject Zone - SUCCESS: found=" . result[1].id . " searchTime=" . SearchStats.searchTimeMs . "ms foundInZone=" . SearchStats.foundInZone)
        return result[1].id
    }

    ; No subject pattern matched - return empty string for manual entry
    return ""
}

;
; Suspend detection with resume option
SuspendDetection() {
    global SessionState
    previousState := SessionState
    SessionState := PAUSED
    ; WriteLog("Detection paused. Previous state: " . previousState)
    
    MsgBox("Upchieve suspended`n`nPress OK to resume", "Detection Paused", "OK")
    
    ; Resume to appropriate state
    if (previousState == IN_SESSION) {
        SessionState := IN_SESSION
        ; WriteLog("Detection resumed to IN_SESSION state")
    } else {
        SessionState := WAITING_FOR_STUDENT
        ; WriteLog("Detection resumed to WAITING_FOR_STUDENT state")
    }
}

; Session start dialog for name and subject entry
ShowSessionStartDialog() {
    global LastStudentName, LastStudentTopic, SessionStartTime

    ; Create session start GUI
    startGui := Gui("+AlwaysOnTop", "Session Started - Enter Information")

    ; Pre-fill start time
    startTimeFormatted := FormatTime(SessionStartTime, "h:mm tt")

    ; Student name (manual entry)
    startGui.AddText("xm y+10", "Student name:")
    nameEdit := startGui.AddEdit("xm y+5 w200")
    nameEdit.Text := (LastStudentName ? LastStudentName : "")
    ; Set focus to name field for immediate typing
    nameEdit.Focus()

    ; Subject field (pre-filled from OCR if available)
    startGui.AddText("xm y+15", "Subject:")
    subjectEdit := startGui.AddEdit("xm y+5 w200")
    subjectEdit.Text := (LastStudentTopic ? LastStudentTopic : "")

    ; Start time (read-only, pre-filled)
    startGui.AddText("xm y+15", "Start time:")
    startTimeEdit := startGui.AddEdit("xm y+5 w200 ReadOnly")
    startTimeEdit.Text := startTimeFormatted

    ; Previous session info section (if available from last session feedback)
    static lastSessionInfo := ""
    if (lastSessionInfo != "") {
        startGui.AddText("xm y+20", "Previous session info:")
        startGui.AddText("xm y+5 w350", lastSessionInfo)
    }

    ; Buttons
    continueBtn := startGui.AddButton("xm y+20 w100 h30", "Continue")
    pauseBtn := startGui.AddButton("x+10 yp w100 h30", "Pause")

    ; Button event handlers
    result := ""

    ContinueHandler(*) {
        UpdateSessionInfo()  ; Capture values before destruction
        result := "Continue"
        startGui.Destroy()
    }

    PauseHandler(*) {
        UpdateSessionInfo()  ; Capture values before destruction
        result := "Pause"
        startGui.Destroy()
    }

    continueBtn.OnEvent("Click", ContinueHandler)
    pauseBtn.OnEvent("Click", PauseHandler)

    ; Update global variables from user input
    UpdateSessionInfo() {
        global LastStudentName, LastStudentTopic
        LastStudentName := Trim(nameEdit.Text)
        LastStudentTopic := Trim(subjectEdit.Text)
    }

    ; Show dialog and wait for user input
    startGui.Show()

    ; Wait for user to close dialog
    while (!result) {
        Sleep 100
    }

    return result
}

; Show session feedback dialog and return continue choice
ShowSessionFeedbackDialog() {
    global LastStudentName, LastStudentTopic, SessionStartTime, SessionEndTime
    
    ; Set session end time
    SessionEndTime := A_Now
    
    ; Create session feedback GUI
    feedbackGui := Gui("+AlwaysOnTop", "Session Complete - Feedback")
    
    ; Student name (manual entry required)
    feedbackGui.AddText("xm y+10", "Student name (enter manually):")
    nameEdit := feedbackGui.AddEdit("xm y+5 w200")
    nameEdit.Text := (LastStudentName ? LastStudentName : "")
    ; Set focus to name field for immediate typing
    nameEdit.Focus()
    
    ; Additional fields
    feedbackGui.AddText("xm y+15", "Grade:")
    gradeEdit := feedbackGui.AddEdit("xm y+5 w50")
    
    feedbackGui.AddText("x+20 yp", "Subject:")
    subjectEdit := feedbackGui.AddEdit("x+5 yp w150")
    subjectEdit.Text := (LastStudentTopic ? LastStudentTopic : "")
    
    feedbackGui.AddText("xm y+15", "Topic:")
    topicEdit := feedbackGui.AddEdit("xm y+5 w350")
    
    ; Math checkbox - auto-check if subject is math-related
    isMathSubject := false
    if (LastStudentTopic != "") {
        subjectLower := StrLower(LastStudentTopic)
        isMathSubject := (InStr(subjectLower, "math") > 0 || 
                         subjectLower == "pre-algebra" || 
                         subjectLower == "algebra" || 
                         subjectLower == "statistics")
    }
    mathCheck := feedbackGui.AddCheckbox("xm y+15" . (isMathSubject ? " Checked" : ""), "Math subject")
    
    ; Session characteristic checkboxes
    feedbackGui.AddText("xm y+15", "Session characteristics:")
    initialCheck := feedbackGui.AddCheckbox("xm y+5 Checked", "Initial response")
    seriousCheck := feedbackGui.AddCheckbox("x+120 yp Checked", "Serious question") 
    leftCheck := feedbackGui.AddCheckbox("xm", "Left abruptly")
    stoppedCheck := feedbackGui.AddCheckbox("x+120 yp", "Stopped responding")
    feedbackGui.AddText("xm y+5", "Good progress (0-1):")
    progressEdit := feedbackGui.AddEdit("x+10 yp w60")
    progressEdit.Text := "1.0"
    
    ; Last response time
    feedbackGui.AddText("xm y+15", "Last message time (HH:MM):")
    lastMsgEdit := feedbackGui.AddEdit("xm y+5 w100")
    
    ; Comments
    feedbackGui.AddText("xm y+15", "Comments:")
    commentsEdit := feedbackGui.AddEdit("xm y+5 w350")
    
    ; Buttons
    feedbackGui.AddText("xm y+15", "Continue looking for students?")
    yesBtn := feedbackGui.AddButton("xm y+5 w80 h30", "Yes")
    noBtn := feedbackGui.AddButton("x+10 yp w80 h30", "No") 
    pauseBtn := feedbackGui.AddButton("x+10 yp w80 h30", "Pause")
    skipBtn := feedbackGui.AddButton("x+10 yp w80 h30", "Skip")
    
    ; Button event handlers
    result := ""
    yesBtn.OnEvent("Click", (*) => (LogSessionFeedbackCSV(), result := "Restart", feedbackGui.Destroy()))
    noBtn.OnEvent("Click", (*) => (LogSessionFeedbackCSV(), result := "No", feedbackGui.Destroy()))
    pauseBtn.OnEvent("Click", (*) => (LogSessionFeedbackCSV(), result := "Cancel", feedbackGui.Destroy()))
    skipBtn.OnEvent("Click", (*) => (SaveCorrectionsOnly(), result := "Restart", feedbackGui.Destroy()))
    
    ; Function to save corrections only (for Skip button)
    SaveCorrectionsOnly() {
        ; Save corrections if user modified the names/subjects
        global LastStudentName, LastStudentTopic, LastRawStudentName
        
        ; Check if student name was corrected
        finalName := Trim(nameEdit.Text)
        if (finalName != "" && LastRawStudentName != "" && finalName != LastStudentName) {
            ; User corrected the student name - save correction mapping from raw OCR to final name
            SaveCorrection(LastRawStudentName, finalName)
            WriteLog("Saved name correction: '" . LastRawStudentName . "' -> '" . finalName . "'")
        }
        
        ; Check if subject was corrected  
        finalSubject := Trim(subjectEdit.Text)
        if (finalSubject != "" && finalSubject != LastStudentTopic) {
            ; User corrected the subject - save correction mapping
            SaveCorrection(LastStudentTopic, finalSubject)
            WriteLog("Saved subject correction: '" . LastStudentTopic . "' -> '" . finalSubject . "'")
        }
        
        ; Rename OCR training screenshot with corrected student name
        finalName := Trim(nameEdit.Text)
        if (finalName != "") {
            RenameScreenshotWithCorrectedName(finalName)
        }
        
        WriteLog("Session skipped - corrections saved but no CSV log entry created")
    }
    
    ; Function to log session feedback in CSV format
    LogSessionFeedbackCSV() {
        ; Save corrections if user modified the names/subjects
        global LastStudentName, LastStudentTopic, LastRawStudentName
        
        ; Check if student name was corrected
        finalName := Trim(nameEdit.Text)
        if (finalName != "" && LastRawStudentName != "" && finalName != LastStudentName) {
            ; User corrected the student name - save correction mapping from raw OCR to final name
            SaveCorrection(LastRawStudentName, finalName)
            WriteLog("Saved name correction: '" . LastRawStudentName . "' -> '" . finalName . "'")
        }
        
        ; Check if subject was corrected  
        finalSubject := Trim(subjectEdit.Text)
        if (finalSubject != "" && finalSubject != LastStudentTopic) {
            ; User corrected the subject - save correction mapping
            SaveCorrection(LastStudentTopic, finalSubject)
            WriteLog("Saved subject correction: '" . LastStudentTopic . "' -> '" . finalSubject . "'")
        }
        
        ; Calculate session duration in minutes
        duration := ""
        if (SessionStartTime != "" && SessionEndTime != "") {
            startSecs := DateDiff(SessionStartTime, "19700101000000", "Seconds")
            endSecs := DateDiff(SessionEndTime, "19700101000000", "Seconds")
            duration := Round((endSecs - startSecs) / 60)
        }
        
        ; Format times
        rtime := FormatTime(SessionStartTime, "M/d/yy")
        startTime := FormatTime(SessionStartTime, "H:mm")
        endTime := FormatTime(SessionEndTime, "H:mm")
        
        ; Build CSV row following exact column specification
        csvRow := ""
        csvRow .= "," ; Column 1: blank
        csvRow .= rtime . "," ; Column 2: date
        csvRow .= startTime . "," ; Column 3: starting time
        csvRow .= startTime . "," ; Column 4: starting time (same as column 3)
        csvRow .= endTime . "," ; Column 5: ending time  
        csvRow .= "," ; Column 6: blank
        csvRow .= StrReplace(StrReplace(nameEdit.Text, "`n", " "), "`r", "") . "," ; Column 7: name
        csvRow .= gradeEdit.Text . "," ; Column 8: grade
        csvRow .= "," ; Column 9: blank
        csvRow .= "," ; Column 10: blank (no dialog input)
        csvRow .= StrReplace(StrReplace(subjectEdit.Text, "`n", " "), "`r", "") . "," ; Column 11: subject (from dialog)
        csvRow .= StrReplace(StrReplace(topicEdit.Text, "`n", " "), "`r", "") . "," ; Column 12: Topic (from dialog)
        csvRow .= (mathCheck.Value ? "1" : "0") . "," ; Column 13: Math
        csvRow .= duration . "," ; Column 14: duration
        csvRow .= (initialCheck.Value ? "1" : "0") . "," ; Column 15: Initial response
        csvRow .= (seriousCheck.Value ? "1" : "0") . "," ; Column 16: Serious question  
        csvRow .= (leftCheck.Value ? "1" : "0") . "," ; Column 17: Left abruptly
        csvRow .= (stoppedCheck.Value ? "1" : "0") . "," ; Column 18: Stopped resp
        csvRow .= progressEdit.Text . "," ; Column 19: Good progress (float 0-1)
        csvRow .= lastMsgEdit.Text . "," ; Column 20: last response
        csvRow .= StrReplace(StrReplace(commentsEdit.Text, "`n", " "), "`r", "") ; Column 21: comments (no trailing comma)
        
        ; Rename OCR training screenshot with corrected student name
        finalName := Trim(nameEdit.Text)
        if (finalName != "") {
            RenameScreenshotWithCorrectedName(finalName)
        }
        
        WriteAppLog(csvRow)
    }
    
    ; Show dialog and wait for result
    feedbackGui.Show("w370 h550")
    
    ; Wait for user action
    while (result == "") {
        Sleep(50)
    }
    
    return result
}

; Prevent system from going to sleep while script is running
; 0x80000003 = ES_SYSTEM_REQUIRED | ES_CONTINUOUS (keeps system awake)
DllCall("kernel32.dll\SetThreadExecutionState", "UInt", 0x80000003)


; Load blocked names list
; BlockedNames := LoadBlockedNames()

; Manual session start/end function
EndSession() {
    WriteLog("DEBUG: EndSession() called - Current state: " . SessionState)
    global SessionState, LastStudentName, LastStudentTopic, LastRawStudentName, LastRawStudentTopic, SessionStartTime
    
    if (SessionState == IN_SESSION) {
        ; Currently in session - end it with feedback dialog
        continueResult := ShowSessionFeedbackDialog()
        
        if (continueResult = "Restart") {
            WriteLog("Manual session end - restarting script")
            Reload
        } else if (continueResult = "No") {
            CleanExit()
        } else {  ; Cancel (Pause)
            SessionState := PAUSED
            SuspendDetection()
            SessionState := WAITING_FOR_STUDENT  ; Resume after pause dialog
        }
    } else {
        ; Not in session - start a manual session
        ; Clear previous session data since we don't have OCR info
        LastStudentName := ""
        LastStudentTopic := ""
        LastRawStudentName := ""
        ; LastRawStudentTopic removed - no longer needed
        SessionStartTime := A_Now

        ; Show session start dialog for manual session
        dialogResult := ShowSessionStartDialog()

        if (dialogResult == "Pause") {
            SessionState := PAUSED
            WriteLog("Manual session start paused via dialog")
            return
        }

        ; Change to IN_SESSION state
        SessionState := IN_SESSION
        global lastSessionEndCheck := A_TickCount  ; Initialize session end check timer
        WriteLog("Manual session start - no OCR data available, initialized session end detection")
    }
}

; Summarize student based on upchieve_app.log
SummarizeStudent(name) {
    logFile := "upchieve_app.log"
    
    ; Check if log file exists
    if (!FileExist(logFile)) {
        return name . "`nNo log file found."
    }
    
    try {
        fileContent := FileRead(logFile)
        lines := StrSplit(fileContent, "`n", "`r")
        
        studentEntries := []
        
        ; Parse CSV lines (skip header and non-CSV lines)
        for index, line in lines {
            if (index == 1 || InStr(line, "Upchieve Detector") || Trim(line) == "") {
                continue  ; Skip header and log messages
            }
            
            ; Split CSV line
            fields := StrSplit(line, ",")
            if (fields.Length < 21) {
                continue  ; Skip malformed lines
            }
            
            ; Extract relevant fields (1-indexed CSV columns)
            studentName := Trim(fields[7])   ; Column 7: Name
            date := Trim(fields[2])          ; Column 2: RTime (date)
            subject := Trim(fields[11])      ; Column 11: Subject
            topic := Trim(fields[12])        ; Column 12: Topic
            duration := Trim(fields[14])     ; Column 14: Duration
            goodProgress := Trim(fields[19]) ; Column 19: Good progress
            comments := Trim(fields[21])     ; Column 21: Comments
            
            ; Check if this entry matches the student name (case-insensitive)
            if (StrLower(studentName) == StrLower(name) && studentName != "") {
                studentEntries.Push({
                    date: date,
                    subject: subject,
                    topic: topic,
                    duration: duration,
                    goodProgress: goodProgress,
                    comments: comments
                })
            }
        }
        
        ; Sort entries by date in reverse chronological order
        ; Simple bubble sort (good enough for small datasets)
        if (studentEntries.Length > 1) {
            Loop studentEntries.Length - 1 {
                i := A_Index
                Loop studentEntries.Length - i {
                    j := A_Index
                    ; Compare dates (assuming MM/d/yy format)
                    if (CompareDates(studentEntries[j].date, studentEntries[j+1].date) < 0) {
                        temp := studentEntries[j]
                        studentEntries[j] := studentEntries[j+1]
                        studentEntries[j+1] := temp
                    }
                }
            }
        }
        
        ; Build summary (up to 5 most recent visits)
        summary := name . "`n"
        maxEntries := Min(5, studentEntries.Length)
        
        for i, entry in studentEntries {
            if (i > maxEntries) {
                break
            }
            
            ; Format: {date}\t{subject}: {topic} ({goodProgress}, {duration} min). {comments}
            line := entry.date . "`t"
            if (entry.subject != "") {
                line .= entry.subject
            }
            if (entry.topic != "") {
                line .= ": " . entry.topic
            }
            line .= " (" . entry.goodProgress . ", " . entry.duration . " min)"
            if (entry.comments != "") {
                line .= ". " . entry.comments
            }
            summary .= line . "`n"
        }
        
        return (studentEntries.Length > 0) ? summary : name . "`nNo sessions found."
        
    } catch Error as e {
        return name . "`nError reading log file: " . e.message
    }
}

; Helper function to compare dates in MM/d/yy format
; Returns: >0 if date1 > date2, <0 if date1 < date2, 0 if equal
CompareDates(date1, date2) {
    ; Convert MM/d/yy to comparable format YYYYMMDD
    ConvertDate(dateStr) {
        if (RegExMatch(dateStr, "(\d{1,2})/(\d{1,2})/(\d{2})", &match)) {
            month := Format("{:02d}", Integer(match[1]))
            day := Format("{:02d}", Integer(match[2]))
            year := "20" . match[3]  ; Assume 20xx
            return year . month . day
        }
        return "00000000"  ; Invalid date sorts to beginning
    }
    
    num1 := Integer(ConvertDate(date1))
    num2 := Integer(ConvertDate(date2))
    return num1 - num2
}


; Clean exit function to restore normal sleep behavior
CleanExit() {
    ; Restore normal power management
    WriteLog("DEBUG: Exiting`n")
    DllCall("kernel32.dll\SetThreadExecutionState", "UInt", 0x80000000)
    ExitApp
}

; Hotkey definitions
^+q::CleanExit()
^+h::SuspendDetection()
^+a::{
    WriteLog("DEBUG: Ctrl+Shift+A hotkey triggered")
    EndSession()
}


; Global variables for OCR training screenshots
TempScreenshotPath := ""
SessionCounter := 0

; Capture screenshot of student name region for OCR training
CaptureNameRegion(searchX, searchY, searchWidth, searchHeight, rawOCRResult) {
    global TempScreenshotPath, SessionCounter, targetWindowID
    
    ; Create ocr_training folder if it doesn't exist
    trainingFolder := "ocr_training"
    if (!DirExist(trainingFolder)) {
        try {
            DirCreate(trainingFolder)
            WriteLog("Created OCR training folder: " . trainingFolder)
        } catch Error as e {
            WriteLog("ERROR: Failed to create OCR training folder - " . e.message)
            return ""
        }
    }
    
    ; Generate temp filename with timestamp and session counter
    SessionCounter++
    timestamp := FormatTime(A_Now, "yyyyMMdd_HHmmss")
    tempFilename := trainingFolder . "\temp_" . timestamp . "_" . Format("{:03d}", SessionCounter) . ".bmp"
    
    ;; Convert window coordinates to screen coordinates and create wider capture area
    ; WinGetPos(&winX, &winY, , , targetWindowID)
    ; baseScreenX := Floor(winX + searchX)
    ; baseScreenY := Floor(winY + searchY)
    baseScreenX := searchX
    baseScreenY := searchY

    ; Capture wider area for testing (500x300 instead of original size)
    captureWidth := 500
    captureHeight := 300
    screenX := baseScreenX - 125  ; Center wider area around OCR zone
    screenY := baseScreenY - 105

    ; Capture screenshot of the region
    try {
        ; Use AutoHotkey's ImageSearch function to capture region
        ; Alternative approach: Use GDI+ to capture the specific region
        success := CaptureRegionToFile(screenX, screenY, captureWidth, captureHeight, tempFilename)
        
        if (success) {
            TempScreenshotPath := tempFilename  ; Store for later rename
            WriteLog("DEBUG: OCR training screenshot captured: " . tempFilename . " (OCR: '" . rawOCRResult . "')")
            return tempFilename
        } else {
            WriteLog("ERROR: Failed to capture OCR training screenshot")
            return ""
        }
    } catch Error as e {
        WriteLog("ERROR: Screenshot capture failed - " . e.message)
        return ""
    }
}

; Capture screenshot of blocking pattern search region for debugging
CaptureBlockingRegion(searchX, searchY, searchWidth, searchHeight, debugLabel) {
    global SessionCounter, targetWindowID

    ; Create ocr_training folder if it doesn't exist
    trainingFolder := "ocr_training"
    if (!DirExist(trainingFolder)) {
        try {
            DirCreate(trainingFolder)
            WriteLog("Created OCR training folder: " . trainingFolder)
        } catch Error as e {
            WriteLog("ERROR: Failed to create OCR training folder - " . e.message)
            return ""
        }
    }

    ; Generate debug filename with timestamp and counter
    SessionCounter++
    timestamp := FormatTime(A_Now, "yyyyMMdd_HHmmss")
    tempFilename := trainingFolder . "\blocking_" . timestamp . "_" . Format("{:03d}", SessionCounter) . "_" . debugLabel . ".bmp"

    ; Convert window coordinates and create wider capture area
    baseScreenX := searchX
    baseScreenY := searchY

    ; Capture wider area for testing (500x300 instead of original size)
    captureWidth := 500
    captureHeight := 300
    screenX := baseScreenX - 125  ; Center wider area around blocking zone
    screenY := baseScreenY - 105

    ; Capture screenshot of the region
    try {
        success := CaptureRegionToFile(screenX, screenY, captureWidth, captureHeight, tempFilename)

        if (success) {
            WriteLog("DEBUG: Blocking region screenshot captured: " . tempFilename . " (Label: '" . debugLabel . "')")
            return tempFilename
        } else {
            WriteLog("ERROR: Failed to capture blocking region screenshot")
            return ""
        }
    } catch Error as e {
        WriteLog("ERROR: Blocking screenshot capture failed - " . e.message)
        return ""
    }
}

; Helper function to capture screen region to PNG file
CaptureRegionToFile(screenX, screenY, width, height, filename) {
    global targetWindowID
    try {
        ; Convert (x, y, width, height) to (x1, y1, x2, y2) format for SavePic
        x1 := screenX
        y1 := screenY
        x2 := screenX + width - 1
        y2 := screenY + height - 1
/* 
        ; Debug: Log final coordinates passed to FindText().SavePic()
        WriteLog("DEBUG: SavePic coordinates - X1:" . x1 . " Y1:" . y1 . " X2:" . x2 . " Y2:" . y2 . " (screen coords)")
        WriteLog("DEBUG: SavePic region size - W:" . width . " H:" . height)

        ; Temporarily unbind from window for screenshot to use pure screen coordinates
        ; Store current bind settings
        currentBoundID := FindText().BindWindow(0, 0, 1, 0)  ; get_id = 1
        currentBoundMode := FindText().BindWindow(0, 0, 0, 1)  ; get_mode = 1

        ; Unbind from window
        FindText().BindWindow(0, 0)

 */
        ; Take screenshot with screen coordinates
        FindText().SavePic(filename, x1, y1, x2, y2, 1)

        ; ; Restore previous bind settings
        ; if (currentBoundID > 0) {
        ;     FindText().BindWindow(currentBoundID, currentBoundMode)
        ; }

        ; Verify file was created
        if (FileExist(filename)) {
            return true
        } else {
            WriteLog("ERROR: Screenshot file was not created: " . filename)
            return false
        }
    } catch Error as e {
        WriteLog("ERROR: Screenshot capture failed - " . e.message)
        return false
    }
}

; Rename temp screenshot file to use corrected student name
RenameScreenshotWithCorrectedName(correctedName) {
    global TempScreenshotPath
    
    if (TempScreenshotPath == "" || !FileExist(TempScreenshotPath)) {
        return false
    }
    
    ; Clean the corrected name for filename use
    cleanName := RegExReplace(correctedName, '[<>:"/\\|?*]', "_")  ; Replace invalid chars
    cleanName := Trim(cleanName)
    if (cleanName == "") {
        cleanName := "Unknown"
    }
    
    ; Generate new filename with corrected name
    timestamp := FormatTime(A_Now, "yyyyMMdd_HHmmss")
    trainingFolder := "ocr_training"
    newFilename := trainingFolder . "\" . cleanName . "_" . timestamp . ".bmp"
    
    ; Handle filename collisions
    counter := 1
    while (FileExist(newFilename)) {
        counter++
        newFilename := trainingFolder . "\" . cleanName . "_" . timestamp . "_" . counter . ".bmp"
    }
    
    ; Rename the file
    try {
        FileMove(TempScreenshotPath, newFilename)
        WriteLog("OCR training screenshot renamed: " . TempScreenshotPath . " -> " . newFilename)
        TempScreenshotPath := ""  ; Clear temp path
        return true
    } catch Error as e {
        WriteLog("ERROR: Failed to rename OCR training screenshot - " . e.message)
        return false
    }
}

; Auto-start detection on script launch
StartDetector()

StartDetector() {
    global
    WriteLog("Upchieve Detector starting up")

/*     ; Testing problem with finding Upgrade targets
    MsgBox("Checking for popup ")
    UpgradeTarget := "|<Upgrade>*196$93.zzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzwTwQ03zk3y03zzzzXzXU07w0Dk07zzzwTwQDUz1Uy7UTzzzXzXVz3kz3kz3zzzwTwQDwQDwS7wTzzzXzXVzVVzVkzVzzzwTwQDwATzy7wDzzzXzXVzXXzzkzXzzzwTwQDsQTzy7sTzzzXzXVy3Xzzky3zzzwTwQ00wT0C00zzzzXzXU0TXs1k0TzzzwTwQDzwTwC7XzzzzXzXVzzXzVkwDzzzwDwQDzwDwC7lzzzzVz3VzzlzVky7zzzy7sQDzy7wC7sTzzzkQ7VzzsC1kz3zzzz01wDzzU0y7wDzzzy0zVzzz0Dkzkzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzw"
               . "|<UpgradeGray2Two_wide>*230$137.00M001zzzzzzzzzzzzzzzzy00k007zzzzzzzzzzzzzzzzw00U00Dzzzzzzzzzzzzzzzzs01U00Tzzzzzzztzls0TzUTk03000zzzzzzzznzXk0Dw0DU02003zzzzzzzzbz7bwDkwD004007zzzzzzzzDyDDyD7yS00800DzzzzzzzyTwSTwSDwQ00M00Tzzzzzzzwzswzwwzws00k00zzzzzzzztzltztlzzk01U01zzzzzzzznzXnzXXzzU03003zzzzzzzzbz7bz77zz006007zzzzzzzzDyDDwSDzy00A00DzzzzzzzyTwS01wT0Q00M00Tzzzzzzzwzsw07sy0s00k00zzzzzzzztzltzzlztk01U01zzzzzzzznzXnzzXznU03003zzzzzzzzbz7bzzbzb004007zzzzzzzzDyTDzz7zC00800DzzzzzzzyDsyTzz7yQ00E00TzzzzzzzyDXwzzy7ks01U00Tzzzzzzzy0Dtzzy03k03000zzzzzzzzz0znzzz0TU04001zzzzzzzzzzzzzzzzz00M003zzzzzzzzzzzzzzzzz"
               . "|<New>*134$76.7U07U00000000T00S000000001y01s000000007s07U00000000Tk0S000000001zU1s000000007y07U00000000Tw0S01y0Q0Q0Fvk1s0Ty1s1s17bU7U3zw7U7U4SD0S0S3sC0y0Fsw1s3k7Us3w37Vs7US0C3kDkAS7kS1s0w71r0lsD1s703kQ7Q37US7UQ071kQsQS1wS3zzw7VXVls3lsDzzkCCC77U7bUzzz0ssQQS0TS3k003XVnVs0xsD000DQ7C7U1zUQ000RkCsS07y1s001z0vVs0Ds7U007s3w7U0zUD0C0DU7kS01y0z1s0y0T1s03s1zzU3k1s7U0DU1zs0D07US00S01y00Q0C00000000000000000000000002"
    target := UpgradeTarget
    result := FindText(,, 800,600,1500,1400, 0.05,0.1, target)
    if (result) {
        MsgBox("Found target " . result[1].id . " at " . result[1].1  . "," . result[1].2)
    } else {
        MsgBox("Target not found")
    }
 */   

    ; Combined startup dialog with mode selection
    modeResult := MsgBox("Upchieve detector will search for 'Waiting Students' page and start monitoring automatically.`n`nSelect mode, then click OK and immediately click in the UPchieve browser window to identify it.`n`nYes = LIVE mode (clicks students)`nNo = TESTING mode (no clicking)`nCancel = Exit", "Upchieve Detector - Select Mode & Click Window", "YNC Default2 4096")
    if (modeResult = "Cancel") {
        CleanExit()  ; Exit application
    }
    
    LiveMode := (modeResult = "Yes")
    modeText := LiveMode ? "LIVE" : "TESTING"
    
    ; Wait for user to click and capture the window
    global targetWindowID := ""
    ; Show tooltip that follows mouse cursor
    while (!GetKeyState("LButton", "P")) {
        MouseGetPos(&mouseX, &mouseY)
        ToolTip "Click on the UPchieve browser window now...", , , 3
        Sleep(50)
    }
    KeyWait("LButton", "U")  ; Wait for button release
    MouseGetPos(&mouseX, &mouseY, &targetWindowID)  ; Get window ID under mouse
    ToolTip "", , , 3  ; Clear tooltip ID 3
    
    ; Bind FindText to the selected window for improved performance and reliability
    ; Mode 4 is essential for proper window targeting
    bindResult := FindText().BindWindow(targetWindowID, 4)
;    WriteLog("DEBUG: BindWindow result for ID " . targetWindowID . " with mode 4: " . (bindResult ? "Success" : "Failed"))
    
    ; Verify BindWindow is working by checking bound ID and mode
    boundID := FindText().BindWindow(0, 0, 1, 0)  ; get_id = 1
    boundMode := FindText().BindWindow(0, 0, 0, 1)  ; get_mode = 1
    
    ; Confirm window selection
;    MsgBox("Window selected! Starting " . modeText . " mode detector...", "Window Selected", "OK 4096")
    
    ; Skip PageTarget detection - we already have the right window
    ; Go directly to header detection in known zones
    WinGetClientPos(, , &winWidth, &winHeight, targetWindowID)  ; Get window dimensions

    ; Check for upgrade popup that might be blocking the page
    if (CheckUpgradePopups()) {
        WriteLog("DEBUG: Dismissed upgrade popup before header detection")
    }

    ; Find header targets directly in expected zones (no PageTarget dependency)
    ; FindHeaders() will not return until all headers are found or user cancels
    FindHeaders()
    lastPageCheck := A_TickCount

    ToolTip "Found 'Waiting Students' page! Found all 3/3 headers. Starting " . modeText . " mode detector...", 10, 50
    Sleep 1000
    ToolTip ""
    
    IsActive := true
    
    ; Main detection loop
    while (IsActive) {
        ; Check for upgrade popup first (before headers) - it can obscure header detection
        if (SessionState == WAITING_FOR_STUDENT) {
            if (CheckUpgradePopups()) {
                continue  ; Skip to next iteration after handling upgrade
            }
        }

        ; Periodic header re-detection (every 30 seconds) to handle layout changes
        ; Only do this when WAITING_FOR_STUDENT, not during sessions
        if (SessionState == WAITING_FOR_STUDENT && A_TickCount - lastPageCheck > 30000) {
            FindHeaders()  ; Re-find headers quietly (skip logging)
            lastPageCheck := A_TickCount
        }
        
        ; Check for session end: SessionEndedTarget appears while we're IN_SESSION (every 2 seconds)
        ; SessionEndedTarget is located in upper-right area: width-600,0 to width,350
        if (SessionState == IN_SESSION) {
            if (A_TickCount - lastSessionEndCheck > 2000) {
            WinGetClientPos(, , &winWidth, &winHeight, targetWindowID)
            sessionEndZone := SearchZone(0, 0, winWidth, winHeight)

            ; Debug: Log session end search attempts (every 10th check to avoid spam)
            static sessionEndCheckCount := 0
            sessionEndCheckCount++
            if (tempResult := FindTextInZones(SessionEndedTarget, sessionEndZone, "", 0.0, 0.03)) {
                WriteLog("DEBUG: SessionEndedTarget found at " . tempResult[1].x . "," . tempResult[1].y)
                ; Session ended - show session feedback dialog
                continueResult := ShowSessionFeedbackDialog()
                
                if (continueResult = "Restart") {
                    WriteLog("DEBUG: Session ended - restarting script")
                    Reload
                } else if (continueResult = "No") {
                    CleanExit()
                } else {  ; Cancel (Pause)
                    global SessionState
                    SessionState := PAUSED
                    SuspendDetection()
                    SessionState := WAITING_FOR_STUDENT  ; Resume after pause dialog
                }
            }
            
            ; Always update the timer, whether target was found or not
            lastSessionEndCheck := A_TickCount
            }
        }
        
        ; Permanent status tooltip - update every loop iteration
        ; Use window-relative coordinates for tooltip
        CoordMode("ToolTip", "Window")
        tooltipX := 600
        tooltipY := 225
        
        ; Debug: Log state changes and show tooltip only when state changes
        static lastLoggedState := ""
        if (SessionState != lastLoggedState) {
            WriteLog("DEBUG: State changed from '" . lastLoggedState . "' to '" . SessionState . "'")
            lastLoggedState := SessionState

            ; Show tooltip only when state changes
            if (SessionState == WAITING_FOR_STUDENT) {
                ToolTip "State: Waiting for Student", tooltipX, tooltipY, 2
            } else if (SessionState == IN_SESSION) {
                ToolTip "State: In Session", tooltipX, tooltipY, 2
            } else {
                ToolTip "State: Paused", tooltipX, tooltipY, 2
            }
        }
        
        ; Only scan for waiting students if we're in the right state
        if (SessionState == WAITING_FOR_STUDENT) {
            ; Calculate search zones based on header positions with window coordinates
            global waitTimeHeaderPos
            WinGetClientPos(, , &winWidth, &winHeight, targetWindowID)
            
            ; Use precise header-based positioning: x-5, y+95, 175x30 from WaitTimeHeader upper-left
            waitingZone1 := SearchZone(waitTimeHeaderPos.x - 5, waitTimeHeaderPos.y + 97, waitTimeHeaderPos.x + 50, waitTimeHeaderPos.y + 132)
            waitingZone2 := SearchZone(waitTimeHeaderPos.x - 10, waitTimeHeaderPos.y + 85, waitTimeHeaderPos.x + 70, waitTimeHeaderPos.y + 145)  ; Slightly larger fallback
            
            ; Debug: Log WaitingTarget search zone (once per monitoring session)
            static waitingZoneLogged := false
            if (!waitingZoneLogged) {
                WriteLog("DEBUG: WaitingTarget search zone: " . waitingZone1.ToString())
                waitingZoneLogged := true
            }

            ; Use FindText wait to continuously search for 60 seconds in primary zone
            ; Could use larger zone (waitingZone2) if needed for better coverage
            result := FindText(&waitingX:='wait', &waitingY:=60, waitingZone1.x1, waitingZone1.y1, waitingZone1.x2, waitingZone1.y2, 0.15, 0.05, WaitingTarget)

            ; Debug: Only log when student is found (first detection)
            if (result) {
                static studentDetectionCount := 0
                studentDetectionCount++
                WriteLog("DETECTION #" . studentDetectionCount . ": WaitingTarget found at " . waitingX . "," . waitingY)
            }

            if (result) {
            global LiveMode
            detectionStartTime := A_TickCount  ; Start timing from WaitingTarget detection

            ; Coordinates are already in waitingX and waitingY from the wait call

            ; Step 1: Activate window immediately (parallel with extraction)
            WinActivate("ahk_id " . targetWindowID)

            ; Step 2: Check for blocked name patterns FIRST (fast visual detection)
            blockResult := CheckBlockedNamePatterns()
            if (blockResult.blocked) {
                WriteLog("BLOCKED: Pattern detected - " . blockResult.name . " - skipping student")
                continue  ; Skip this student entirely
            }

            ; Step 3: Extract topic using fast pattern detection (no OCR)
            topic := ExtractTopic()
            WriteLog("Subject detected: '" . topic . "'")
            
            ; Calculate detection time (blocking check + subject detection)
            detectionTime := A_TickCount - detectionStartTime
            WriteLog("Blocking check + subject detection finished (" . detectionTime . "ms)")

            ; Step 4: Click the student
            if (LiveMode) {
                ; Wait for window activation (started earlier)
                WriteLog("Preparing to click")
                WinWaitActive("ahk_id " . targetWindowID, , 2)  ; Wait up to 2 seconds for activation
                
                ; Click the waiting target (confirmed this works)
                Click waitingX, waitingY  ; Click the waiting target coordinates
                clickTime := A_TickCount - detectionStartTime  ; Total time from detection to click
                WriteLog("CLICK #" . studentDetectionCount . ": Clicked waiting target at " . waitingX . "," . waitingY . " (total from detection: " . clickTime . " ms)")

                ; Wait for session to start loading, then maximize window
                Sleep 2000  ; Wait 2 seconds for session to begin loading
                WinMaximize("ahk_id " . targetWindowID)

                ; Check if click succeeded by verifying if student header is still present
                ; If header still visible, the click was too slow and someone else claimed the student
                WinGetClientPos(, , &winWidth, &winHeight, targetWindowID)
                headerCheckZone := SearchZone(600, 200, 1600, 1300)
                headerCheckResult := FindTextInZones(StudentHeaderTarget, headerCheckZone)
; headerCheckResult := false  ; TEMP OVERRIDE TO SKIP CHECKING FOR TESTING
                if (headerCheckResult) {
                    ; Click failed - student header still present, session didn't open
                    WriteLog("MISSED: ? - " . topic )
                    continue  ; Continue waiting for students, don't change to IN_SESSION
                }

                ; IMMEDIATELY change state to IN_SESSION after clicking (only if successful)
                global SessionState
                SessionState := IN_SESSION
                
                ; Update session tracking variables (no name, subject only)
                global LastStudentName, LastStudentTopic, LastRawStudentName, SessionStartTime
                LastRawStudentName := ""  ; No OCR extraction
                LastStudentName := ""  ; Manual entry required
                LastStudentTopic := topic  ; Direct use of pattern-matched subject
                SessionStartTime := A_Now

                ; Log session start
                logMessage := "Session started"
                toolTipMessage := "Session"
                if (LastStudentTopic != "") {
                    logMessage .= " with " . LastStudentTopic
                    toolTipMessage .= " (" . LastStudentTopic . ")"
                }
                logMessage .= " (detection: " . detectionTime . "ms, total: " . clickTime . "ms)"
                WriteLog(logMessage)
                ; Session details will be logged via end-session CSV dialog
                ToolTip(toolTipMessage . " has opened", 10, 50)
                SetTimer(() => ToolTip(), -3000)  ; Clear tooltip after 3 seconds
            } else {
                ; TESTING mode - no name extraction
                global LastStudentName, LastStudentTopic, LastRawStudentName, SessionStartTime
                LastRawStudentName := ""  ; No OCR extraction
                LastStudentName := ""  ; Manual entry required
                LastStudentTopic := topic  ; Direct use of pattern-matched subject
                SessionStartTime := A_Now

                ; Log session start in testing mode
                logMessage := "TESTING: Found student"
                toolTipMessage := "Found student"
                if (LastStudentTopic != "") {
                    logMessage .= " with " . LastStudentTopic
                    toolTipMessage .= " (" . LastStudentTopic . ")"
                }
                logMessage .= " (detection: " . detectionTime . "ms)"
                WriteLog(logMessage)
                ; Session details will be logged via end-session CSV dialog
                ToolTip(toolTipMessage . " waiting", 10, 50)
                SetTimer(() => ToolTip(), -3000)

                ; In testing mode, also simulate being in session for state testing
                global SessionState
                SessionState := IN_SESSION
            }
            
            ; Step 4: Start repeating notification sound (every 2 seconds)
            global SoundTimerFunc
            PlayNotificationSound()  ; Play immediately
            SoundTimerFunc := PlayNotificationSound  ; Store function reference
            SetTimer SoundTimerFunc, 2000  ; Then every 2 seconds
            
            ToolTip ""  ; Clear tooltip
            
            ; Step 5: Show session start dialog for name and subject entry
            dialogResult := ShowSessionStartDialog()

            ; Step 6: Stop the sound and handle dialog result
            if (SoundTimerFunc != "") {
                SetTimer SoundTimerFunc, 0  ; Stop the timer
                SoundTimerFunc := ""
            }

            ; Handle dialog result
            if (dialogResult == "Pause") {
                SessionState := PAUSED
                WriteLog("Session paused via start dialog")
                continue  ; Skip to next loop iteration
            }
            
            ; Continue monitoring for more students (removed break statement)
            }

        }

        ; No sleep needed - FindText wait handles timing
        
        ; Continue monitoring (removed window existence check)
    }
    
    ; Clear tooltip when done
    ToolTip ""
}