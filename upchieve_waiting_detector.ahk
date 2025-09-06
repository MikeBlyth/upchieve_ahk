#Requires AutoHotkey v2.0
#Include FindTextv2.ahk
#Include alphabet.ahk
#Include ocr_functions.ahk
#Include student_database.ahk

; Upchieve Waiting Student Detector
; Hotkeys: Ctrl+Shift+Q to quit, Ctrl+Shift+H to pause/resume, Ctrl+Shift+R to resume from session

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
SessionStartTime := ""
SessionEndTime := ""

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

WaitingTarget := WaitingTarget1

UpgradeTarget :="|<Upgrade>*197$75.zzzzzzzzzzzzzzzzzzzzzzzzzszss07zU7w07z7z700Ds0TU0DszssT1y31wD0z7z73y7Vy7Vy7szssTssTswDsz7z73z33z3Vz3szssTsMzzwDsT7z73z77zzVz7szssTkszzwDkz7z73w77zzVw7szss01sy0Q01z7z700z7k3U0zszssTzszsQD7z7z73zz7z3VsTsTssTzsTsQDXz3y73zzXz3VwDwDksTzwDsQDkzUsD3zzkQ3Vy6y03sTzz01wDsLw1z3zzy0TVzUzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzw"

EndSessionTarget :="|<EndSession>*194$193.00C0000000000000000000000000000000C0000000000000000000000000000000C0000000000000000000000000000000C0000000000000000000000000000000C000000000000000000000000000000060000000000000000000000000000000600000000000000000000000000000007000000000000000000000000000000030000000000000000000000000000000300000000000000000000000000000003U0000000000000000000000000000001U0000000000000000000000000000000k0000000000000000000000000000000k0000000000000000000000000000000M0000000000000000000000000000000Q0000000000000000000000000000000A000000000000000000000000000000060000000000000000S0000000000000070000000000000000D00000000000000300000000zzw000007U007w0000000001U0000000Tzy000003k00DzU000000000k0000000Dzz000001s00Dzs000000000s00000007U0000000w00D0S000000000M00000003k0000000S00D07000000000A00000001s00STU0zD007U103w03w0Ds600000000w00DTs0zzU03k007zU7zUTz300000000S007zy0zzk01w007zs7zsDzlU0000000D003w7Uw3s00zU07US7UQD1sk00000007zw1w3kS0w00DzU3U73k470MM00000003zy0w0sS0S003zw3k3Vs03k0A00000001zz0S0QD0D000TzVzzkzU1y0600000000w00D0C7U7U000zkzzsDz0Tw300000000S007U73k3k0001wTzw1zk3zVU0000000D003k3Vs1s0000SD0007w0Dsk00000007U01s1kw0w0080D7U000D00wQ00000003k00w0sD0S00C07Vs20U7V0C600000001s00S0Q7UT007k7Uw3ks3lkD300000000zzwD0C1zzU01zzUDzkTzkzzVU0000000Tzy7U70Txk00TzU3zk7zkDzUs0000000Dzz3k3U7ss003z00Tk0zU1z0A0000000000000000000000000000000600000000000000000000000000000003U0000000000000000000000000000000k0000000000000000000000000000000M000000000000000000000000000000060000000000000000000000000000000300000000000000000000000000000001k0000000000000000000000000000000M0000000000000000000000000000000600000000000000000000000000000003U0000000000000000000000000000000k0000000000000000000000000000000A0000000000000000000000000000000700000000000000000000000000000001k0000000000000000000000000000000Q0000000000000000000000000000000700000000000000000000000000000001k0000000000000000000000000000000Q0000000000000000000000000000000700000000000000000000000000000001s0000000000000000000000000000E"
FinishTarget :="|<Finish>*225$127.01000000000000000000001U00000000000000000001U00000000000000000000U00000000000000000000k00000000000000000000E00000000000000000000E00000000000000000000M00000000000000000000800000000000000000000400000000000000000000400000000000000000000200000000000000000000300000000000000000000100000000000T0000w0000U0000000000DU000z0000E0000000Dzz7k000TU000M00000007zzXk0007U000800000003zzk000000000400000001s00000000000200000000w00000000000100000000S00D1tz0S0zk0U0000000D007UzzkD0zy0k00000007U03kTzw7Uzz0M00000003k01sDky3ky7kA00000001zz0w7kD1sS1k600000000zzkS3s7kwDU0300000000TzsD1s3sS7y01U0000000D007Uw1wD1zs0E00000007U03kS0y7UTz0800000003k01sD0T3k1zk400000001s00w7UDVs03s200000000w00S3k7kw60w100000000S00D1s3sS7Uy0k0000000D007Uw1wD3zz0800000007U03kS0y7Uzz0400000003k01sD0T3k7y02000000000000000000001U00000000000000000000E000000000000000000008000000000000000000002000000000000000000001000000000000000000000k0000000000000000000E"

StudentHeaderTarget := "|<Student>*146$71.00000000000000000000001w3z00k000003sTzUDU000007nzzkT000000Djzzky000000TTUT1w000000yy0QTznw7k3txw0EzzbsDUTvvy01zzDkT1zzrzk3zyTUy3zzjzw0y0z1wDkzDzy1w1y3sT0yDzy3s3w7ky1w3zw7k7sDVw3s0TsDUDkT3s7m0DkT0TUy7kDa0DUy0z1wDUTT0z1w1y7sTVzzzy3zlzzkzzxzzs7zXzzUzztzzU7z3zD0znkTs03w3wS0T7U00000000000000000000001"
HelpHeaderTarget := "|<HelpHeader>*147$71.0000000000000000000z0001y0T0001y0003w0y0003w0007s1w0007s000Dk3s000Dk000TU7k000TU000z0DU3w0z1sy1y0T0Ty1y3nz3w0y1zy3w7jz7s1w7zy7sDzyDzzsTVyDkTVyTzzky1wTUy3wzzzVzzsz1w3tzzz3zzly3s7nw0y7zzXw7kDbs1wDU07sDUTDk3sT00DkT1yTU7kz1sTUz3wz0DUzzkztzzly0T0zzUznzzXw0y0zy1z7ry7s1w0Tk1yDbk000000000T00000000000y01"
WaitTimeHeaderTarget:="|<WaitTime>*148$97.000000000000000000000000D0000000C0z0T000Dk3007zzzUTUDU007sDU03zzzkDkDk003w7k01zzzs7s7s000w3s00zzzw3y3s00001w000DUS3z1w3y0Tbzw007kDVzUy7zkDnzy003s7kzky7zw7tzz001w3sQsT3zz3wzzU00y1wSSDXsTVy3s000T0yDD7UQ7kz1w000DUDbbXk07sTUy0007k7nnns0zwDkT0003s3tkxw3zy7sDU001w0xsSw3wT3w7k000y0TwDy3sDVy3s000T0Dy7z1wDkz1y000DU7y1z0zzyTUzw007k1z0zUTzzDkTy003s0zUTk7zTbs7z001w0TkDs1y7nw0z000y000000000000000000000000000000000E"

if (ok:=FindText(&X, &Y, 802-150000, 1414-150000, 802+150000, 1414+150000, 0, 0, HelpHeaderTarget))
{
  ; FindText().Click(X, Y, "L")
}

if (ok:=FindText(&X, &Y, 428-150000, 1414-150000, 428+150000, 1414+150000, 0, 0, StudentHeaderTarget))
{
  ; FindText().Click(X, Y, "L")
}


; Debug log function
WriteLog(message) {
    logFile := "debug_log.txt"
    timestamp := FormatTime(A_Now, "yyyy-MM-dd HH:mm:ss")
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

; Convert FindText midpoint coordinates to upper-left coordinates
; Supports both explicit dimensions and automatic parsing from target patterns
GetUpperLeft(centerX, centerY, widthOrTarget, height := 25) {
    ; If third parameter is a string (target pattern), parse dimensions from it
    if (Type(widthOrTarget) == "String") {
        ; Parse width from target pattern format: "|<name>*tolerance$width.hexdata"
        if (RegExMatch(widthOrTarget, "\$(\d+)\.", &match)) {
            width := Integer(match[1])
            return {x: centerX - width / 2, y: centerY - height / 2}
        }
        ; Fallback if pattern parsing fails
        return {x: centerX - 50, y: centerY - 12}  ; Assume 100px width, 25px height
    }
    ; Otherwise treat as explicit width (original behavior)
    else {
        width := widthOrTarget
        return {x: centerX - width / 2, y: centerY - height / 2}
    }
}

; Find all header targets and store their positions for search zone calculations
FindHeaders() {
    global StudentHeaderTarget, HelpHeaderTarget, WaitTimeHeaderTarget, pageRefX, pageRefY
    
    ; Initialize header positions (will be empty if not found)
    global studentHeaderPos := {x: 0, y: 0, found: false}
    global helpHeaderPos := {x: 0, y: 0, found: false}
    global waitTimeHeaderPos := {x: 0, y: 0, found: false}
    
    ; Define precise search areas for each header (250×90px)  
    ; Based on PageTarget CENTER coordinates: Student=-459px, Help=-165px, WaitTime=+204px, Y=+198px
    
    ; Search for Student Header
    X := ""
    Y := ""
    studentSearchX1 := Max(0, pageRefX - 484)
    studentSearchY1 := Max(0, pageRefY + 173)
    studentSearchX2 := Min(A_ScreenWidth, pageRefX - 234)
    studentSearchY2 := Min(A_ScreenHeight, pageRefY + 263)
    if (result := FindText(&X, &Y, studentSearchX1, studentSearchY1, studentSearchX2, studentSearchY2, 0.15, 0.10, StudentHeaderTarget)) {
        upperLeft := GetUpperLeft(X, Y, StudentHeaderTarget)
        studentHeaderPos := {x: upperLeft.x, y: upperLeft.y, found: true}
    }
    
    ; Search for Help Header
    X := ""
    Y := ""
    helpSearchX1 := Max(0, pageRefX - 190)
    helpSearchY1 := Max(0, pageRefY + 173)
    helpSearchX2 := Min(A_ScreenWidth, pageRefX + 60)
    helpSearchY2 := Min(A_ScreenHeight, pageRefY + 263)
    if (result := FindText(&X, &Y, helpSearchX1, helpSearchY1, helpSearchX2, helpSearchY2, 0.15, 0.10, HelpHeaderTarget)) {
        upperLeft := GetUpperLeft(X, Y, HelpHeaderTarget)
        helpHeaderPos := {x: upperLeft.x, y: upperLeft.y, found: true}
    }
    
    ; Search for Wait Time Header
    X := ""
    Y := ""
    waitSearchX1 := Max(0, pageRefX + 179)
    waitSearchY1 := Max(0, pageRefY + 173)
    waitSearchX2 := Min(A_ScreenWidth, pageRefX + 429)
    waitSearchY2 := Min(A_ScreenHeight, pageRefY + 263)
    if (result := FindText(&X, &Y, waitSearchX1, waitSearchY1, waitSearchX2, waitSearchY2, 0.15, 0.10, WaitTimeHeaderTarget)) {
        upperLeft := GetUpperLeft(X, Y, WaitTimeHeaderTarget)
        waitTimeHeaderPos := {x: upperLeft.x, y: upperLeft.y, found: true}
    }
    
    ; Log header detection results
    headersFound := 0
    headerStatus := ""
    if (studentHeaderPos.found) {
        headersFound++
        headerStatus .= "Student "
    }
    if (helpHeaderPos.found) {
        headersFound++
        headerStatus .= "Help "
    }
    if (waitTimeHeaderPos.found) {
        headersFound++
        headerStatus .= "WaitTime "
    }
    
    ; Log detailed results if not all headers found
    if (headersFound < 3) {
        WriteLog("Header detection: " . headersFound . "/3 found (" . Trim(headerStatus) . ")")
    }
    
    return headersFound
}

; Load blocked names from block_names.txt
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
    for index, blockedName in blockedNames {
        if (StrLower(Trim(studentName)) == StrLower(Trim(blockedName))) {
            return true
        }
    }
    return false
}


; Extract student name using header-based positioning with fallback
ExtractStudentNameRaw(baseX, baseY) {
    global studentHeaderPos
    
    if (studentHeaderPos.found && studentHeaderPos.x > 0 && studentHeaderPos.y > 0) {
        ; Use header-based positioning: header position + 96px down, with 25px margins
        searchX := Max(0, studentHeaderPos.x)
        searchY := Max(0, studentHeaderPos.y + 96 - 25)
        searchWidth := Min(250, A_ScreenWidth - searchX)  ; Match column width, bounded
        searchHeight := Min(90, A_ScreenHeight - searchY)
    } else {
        ; Fallback to WaitingTarget-based positioning (original method)
        upperLeftX := baseX - 67
        upperLeftY := baseY - 17
        searchX := upperLeftX - 720
        searchY := upperLeftY - 10
        searchWidth := 400 
        searchHeight := 80
    }
    
    ; Use shared OCR function with default parameters - RAW RESULT ONLY
    result := ExtractTextFromRegion(searchX, searchY, searchX + searchWidth, searchY + searchHeight)
    
    return result.text  ; Return raw OCR result without validation
}

; Extract and validate student name (for post-click processing)
ExtractStudentNameValidated(baseX, baseY) {
    ; Get raw OCR result
    rawName := ExtractStudentNameRaw(baseX, baseY)
    
    ; Validate and correct the student name using the database
    if (rawName != "") {
        validatedName := ValidateStudentName(rawName)
        ; Log both raw OCR and final validated result
        if (rawName != validatedName) {
            WriteLog("OCR: '" . rawName . "' -> Validated: '" . validatedName . "'")
        }
        return validatedName
    }
    
    return ""  ; Return empty string if no text detected
}

; Extract topic using header-based positioning with fallback
ExtractTopicRaw(baseX, baseY) {
    global helpHeaderPos
    
    if (helpHeaderPos.found && helpHeaderPos.x > 0 && helpHeaderPos.y > 0) {
        ; Use header-based positioning: header position + 96px down, with 25px margins
        searchX := Max(0, helpHeaderPos.x)
        searchY := Max(0, helpHeaderPos.y + 96 - 25)
        searchWidth := Min(250, A_ScreenWidth - searchX)  ; Match column width, bounded
        searchHeight := Min(90, A_ScreenHeight - searchY)
    } else {
        ; Fallback: estimate topic position relative to student name position
        ; Assume topic is roughly in the middle of the row
        upperLeftX := baseX - 67
        upperLeftY := baseY - 17
        searchX := upperLeftX - 200  ; Position between student and wait time
        searchY := upperLeftY - 10
        searchWidth := 250  ; Limit to column width
        searchHeight := 80
    }
    
    ; Use shared OCR function with default parameters - RAW RESULT ONLY
    result := ExtractTextFromRegion(searchX, searchY, searchX + searchWidth, searchY + searchHeight)
    
    return result.text  ; Return raw OCR result without validation
}

; Validate topic against known Upchieve subjects with fuzzy matching
ValidateTopicName(ocrResult) {
    ; Define known Upchieve subjects
    knownTopics := [
        "6th Grade Math",
        "7th Grade Math", 
        "8th Grade Math",
        "Pre-algebra",
        "Algebra",
        "Integrated Math",
        "Statistics",
        "Middle School Science",
        "Computer Science A",
        "Computer Science Principles"
    ]
    
    cleanOCR := Trim(ocrResult)
    if (cleanOCR == "") {
        return ""
    }
    
    ; First try exact matches (case insensitive)
    for topic in knownTopics {
        if (cleanOCR = topic) {
            return topic
        }
    }
    
    ; Then try fuzzy matching with edit distance
    bestMatch := ""
    bestDistance := 999
    
    for topic in knownTopics {
        distance := EditDistance(StrLower(cleanOCR), StrLower(topic))
        ; Allow more tolerance for longer topic names
        threshold := (StrLen(topic) > 15) ? 4 : 3
        
        if (distance <= threshold && distance < bestDistance) {
            bestDistance := distance
            bestMatch := topic
        }
    }
    
    ; If we found a close match, return it
    if (bestMatch != "") {
        return bestMatch
    }
    
    ; No close match found - return cleaned OCR result
    cleanTopic := RegExReplace(cleanOCR, "[^\w\s\-'/]", "")
    return cleanTopic
}

; Extract and validate topic (for post-click processing)
ExtractTopicValidated(baseX, baseY) {
    ; Get raw OCR result
    rawTopic := ExtractTopicRaw(baseX, baseY)
    
    ; Validate against known topics
    if (rawTopic != "") {
        validatedTopic := ValidateTopicName(rawTopic)
        ; Log if correction was made
        if (rawTopic != validatedTopic && validatedTopic != "") {
            WriteLog("Topic OCR: '" . rawTopic . "' -> Validated: '" . validatedTopic . "'")
        }
        return validatedTopic
    } else {
        WriteLog("Topic OCR: No text detected")
    }
    
    return ""  ; Return empty string if no text detected
}

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

; Show session feedback dialog and return continue choice
ShowSessionFeedbackDialog() {
    global LastStudentName, LastStudentTopic, SessionStartTime, SessionEndTime
    
    ; Set session end time
    SessionEndTime := A_Now
    
    ; Create session feedback GUI
    feedbackGui := Gui("+AlwaysOnTop", "Session Complete - Feedback")
    
    ; Student name (editable, pre-filled)
    feedbackGui.AddText("xm y+10", "Student name:")
    nameEdit := feedbackGui.AddEdit("xm y+5 w200")
    nameEdit.Text := (LastStudentName ? LastStudentName : "")
    
    ; Additional fields
    feedbackGui.AddText("xm y+15", "Grade:")
    gradeEdit := feedbackGui.AddEdit("xm y+5 w50")
    
    feedbackGui.AddText("x+20 yp", "Subject:")
    subjectEdit := feedbackGui.AddEdit("x+5 yp w150")
    subjectEdit.Text := (LastStudentTopic ? LastStudentTopic : "")
    
    feedbackGui.AddText("xm y+15", "Topic:")
    topicEdit := feedbackGui.AddEdit("xm y+5 w350")
    
    ; Math checkbox
    mathCheck := feedbackGui.AddCheckbox("xm y+15", "Math subject")
    
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
    
    ; Button event handlers
    result := ""
    yesBtn.OnEvent("Click", (*) => (LogSessionFeedbackCSV(), result := "Yes", feedbackGui.Destroy()))
    noBtn.OnEvent("Click", (*) => (LogSessionFeedbackCSV(), result := "No", feedbackGui.Destroy()))
    pauseBtn.OnEvent("Click", (*) => (LogSessionFeedbackCSV(), result := "Cancel", feedbackGui.Destroy()))
    
    ; Function to log session feedback in CSV format
    LogSessionFeedbackCSV() {
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

; Initialize alphabet characters for name extraction at startup
LoadAlphabetCharacters()

; Load blocked names list
BlockedNames := LoadBlockedNames()

; Manual resume from IN_SESSION state
ResumeFromSession() {
    global SessionState
    if (SessionState == IN_SESSION) {
        SessionState := WAITING_FOR_STUDENT
        ; WriteLog("Manual resume: State changed from IN_SESSION to WAITING_FOR_STUDENT")
        MsgBox("Resumed looking for students", "Manual Resume", "OK")
    } else {
        MsgBox("Not currently in session. State: " . SessionState, "Manual Resume", "OK")
    }
}

; Clean exit function to restore normal sleep behavior
CleanExit() {
    ; Restore normal power management
    DllCall("kernel32.dll\SetThreadExecutionState", "UInt", 0x80000000)
    ExitApp
}

; Hotkey definitions
^+q::CleanExit()
^+h::SuspendDetection()
^+r::ResumeFromSession()

; Auto-start detection on script launch
StartDetector()

StartDetector() {
    global
    
    ; Combined startup dialog with mode selection
    modeResult := MsgBox("Upchieve detector will search for 'Waiting Students' page and start monitoring automatically.`n`nYes = LIVE mode (clicks students)`nNo = TESTING mode (no clicking)`nCancel = Exit", "Upchieve Detector Startup", "YNC Default2")
    if (modeResult = "Cancel") {
        CleanExit()  ; Exit application
    }
    
    LiveMode := (modeResult = "Yes")
    modeText := LiveMode ? "LIVE" : "TESTING"
    
    ; Wait for PageTarget to appear with debug info
    pageCheckCount := 0
    X := ""
    Y := ""
    while (!(result := FindText(&X, &Y, 0, 0, A_ScreenWidth, A_ScreenHeight, 0.15, 0.1, PageTarget))) {
        pageCheckCount++
        ToolTip "Looking for 'Waiting Students' page... Check #" pageCheckCount, 10, 50
        Sleep 100
    }
    
    ; PageTarget found - calculate upper-left reference point and find headers
    pageUpperLeft := GetUpperLeft(X, Y, PageTarget)
    pageRefX := pageUpperLeft.x
    pageRefY := pageUpperLeft.y
    lastPageCheck := A_TickCount  ; Track when we last found PageTarget
    lastTooltipShow := A_TickCount  ; Track tooltip display timing
    
    ; Find all header targets for precise search zone positioning
    headersFound := FindHeaders()
    
    ToolTip "Found 'Waiting Students' page! Found " . headersFound . "/3 headers. Starting " . modeText . " mode detector...", 10, 50
    Sleep 1000
    ToolTip ""
    
    ; Log application start
    WriteAppLog("Upchieve Detector started in " . modeText . " mode")
    
    IsActive := true
    
    ; Main detection loop
    while (IsActive) {
        ; Periodic PageTarget re-detection (every 10 seconds) to handle window movement
        if (A_TickCount - lastPageCheck > 10000) {
            tempX := ""
            tempY := ""
            if (tempResult := FindText(&tempX, &tempY, 0, 0, A_ScreenWidth, A_ScreenHeight, 0, 0, PageTarget)) {
                ; PageTarget found - update reference point and re-find headers
                newUpperLeft := GetUpperLeft(tempX, tempY, PageTarget)
                if (newUpperLeft.x != pageRefX || newUpperLeft.y != pageRefY) {
                    ; WriteLog("PageTarget moved: (" . pageRefX . "," . pageRefY . ") -> (" . newUpperLeft.x . "," . newUpperLeft.y . ")")
                    pageRefX := newUpperLeft.x
                    pageRefY := newUpperLeft.y
                    ; Re-find headers since page position changed
                    FindHeaders()
                }
                lastPageCheck := A_TickCount
            } else {
                ; PageTarget not found - keep using previous coordinates
                ; Reduced frequency: only warn every 60 seconds instead of every 5 seconds
                if (A_TickCount - lastPageCheck > 60000) {
                    ; WriteLog("WARNING: PageTarget re-detection failed for >60 seconds")
                }
                lastPageCheck := A_TickCount  ; Reset timer to avoid spam
            }
        }
        
        ; Check for session end: PageTarget appears while we're IN_SESSION  
        if (SessionState == IN_SESSION) {
            tempX := ""
            tempY := ""
            if (tempResult := FindText(&tempX, &tempY, 0, 0, A_ScreenWidth, A_ScreenHeight, 0, 0, PageTarget)) {
                ; Session ended - show session feedback dialog
                ; Session ended - feedback will be logged via CSV dialog
                continueResult := ShowSessionFeedbackDialog()
                
                if (continueResult = "Yes") {
                    global SessionState
                    SessionState := WAITING_FOR_STUDENT
                    ; Use the coordinates we just found and re-find headers
                    newUpperLeft := GetUpperLeft(tempX, tempY, PageTarget)
                    pageRefX := newUpperLeft.x
                    pageRefY := newUpperLeft.y
                    lastPageCheck := A_TickCount
                    ; Re-find headers since we're back on the waiting page
                    FindHeaders()
                } else if (continueResult = "No") {
                    CleanExit()
                } else {  ; Cancel
                    global SessionState
                    SessionState := PAUSED
                    SuspendDetection()
                    SessionState := WAITING_FOR_STUDENT  ; Resume after pause dialog
                }
            }
        }
        
        ; Debug: Show current state briefly (1 second every 5 seconds)
        if (A_TickCount - lastTooltipShow > 5000) {
            ; Time to show tooltip again
            stateText := "State: " . SessionState . " | "
            if (SessionState == WAITING_FOR_STUDENT) {
                ToolTip stateText . "Scanning for upgrade popup and waiting students...", 10, 10
            } else if (SessionState == IN_SESSION) {
                ToolTip stateText . "In session - monitoring for session end...", 10, 10
            } else {
                ToolTip stateText . "Paused", 10, 10
            }
            lastTooltipShow := A_TickCount
        } else if (A_TickCount - lastTooltipShow > 1000) {
            ; Hide tooltip after 1 second
            ToolTip ""
        }
        
        ; Check for upgrade popup first (relative to PageTarget)
        upgradeX1 := pageRefX + 654
        upgradeY1 := pageRefY + 130
        upgradeX2 := upgradeX1 + 325
        upgradeY2 := upgradeY1 + 300
        X := ""
        Y := ""
        if (UpgradeTarget != "" && (result := FindText(&X, &Y, upgradeX1, upgradeY1, upgradeX2, upgradeY2, 0.15, 0.05, UpgradeTarget))) {
            ToolTip "Found upgrade popup! Clicking...", 10, 10
            Click X, Y
            MsgBox "Clicked upgrade popup at " X ", " Y
            Sleep 1000
            continue  ; Skip to next iteration after handling upgrade
        }
        
        ; Only scan for waiting students if we're in the right state
        if (SessionState == WAITING_FOR_STUDENT) {
            ; Calculate search zones based on header positions with fallback
            global waitTimeHeaderPos
            
            if (waitTimeHeaderPos.found && waitTimeHeaderPos.x > 0 && waitTimeHeaderPos.y > 0) {
                ; Use header-based positioning: header position + 100px down, with 25px slack
                waitingX1 := Max(0, waitTimeHeaderPos.x - 25)
                waitingY1 := Max(0, waitTimeHeaderPos.y + 100)
                waitingX2 := Min(A_ScreenWidth, waitingX1 + 334 + 50)  ; Original width + extra slack
                waitingY2 := Min(A_ScreenHeight, waitingY1 + 235)
            } else {
                ; Fallback to PageTarget-based positioning
                waitingX1 := Max(0, pageRefX + 334)
                waitingY1 := Max(0, pageRefY + 309)
                waitingX2 := Min(A_ScreenWidth, waitingX1 + 334)
                waitingY2 := Min(A_ScreenHeight, waitingY1 + 235)
            }
            
            X := ""
            Y := ""
            if (result := FindText(&X, &Y, waitingX1, waitingY1, waitingX2, waitingY2, 0.15, 0.05, WaitingTarget)) {
            global LiveMode
            ToolTip "Found waiting student! Extracting and validating name...", 10, 10
            
            ; Step 1: Extract and VALIDATE student name and topic (with corrections and confirmation)
            validatedName := ExtractStudentNameValidated(X, Y)
            validatedTopic := ExtractTopicValidated(X, Y)
            
            ; Step 2: Check if VALIDATED name is blocked BEFORE clicking
            global BlockedNames
            if (validatedName != "" && IsNameBlocked(validatedName, BlockedNames)) {
                WriteAppLog("BLOCKED: " . validatedName . " - student on block list")
                continue  ; Skip this student and continue monitoring
            }
            
            ; Step 3: Click the student (name validation and confirmation already completed)
            if (LiveMode) {
                ; First click to activate window
                Click X, Y
                Sleep 200  ; Wait 200ms to avoid double-click detection
                ; Second click to select student
                Click X, Y
                
                ; IMMEDIATELY change state to IN_SESSION after clicking
                global SessionState
                SessionState := IN_SESSION
                
                ; Update session tracking variables
                global LastStudentName, LastStudentTopic, SessionStartTime
                LastStudentName := validatedName
                LastStudentTopic := validatedTopic
                SessionStartTime := A_Now
                
                ; Log session start with validated name and topic
                if (validatedName != "") {
                    logMessage := "Session started with " . validatedName
                    toolTipMessage := "Session with " . validatedName
                    if (validatedTopic != "") {
                        logMessage .= ", " . validatedTopic
                        toolTipMessage .= " (" . validatedTopic . ")"
                    }
                    ; Session details will be logged via end-session CSV dialog
                    ToolTip(toolTipMessage . " has opened", 10, 50)
                    SetTimer(() => ToolTip(), -3000)  ; Clear tooltip after 3 seconds
                } else {
                    ; This should rarely happen since validation occurred
                    logMessage := "Session started with student (name unclear after validation)"
                    ; Session details will be logged via end-session CSV dialog
                    ToolTip("Session with student has opened", 10, 50) 
                    SetTimer(() => ToolTip(), -3000)
                }
            } else {
                ; TESTING mode - validation already completed above
                ; Update session tracking variables
                global LastStudentName, LastStudentTopic, SessionStartTime
                LastStudentName := validatedName
                LastStudentTopic := validatedTopic
                SessionStartTime := A_Now
                
                ; Log session start in testing mode with topic
                if (validatedName != "") {
                    logMessage := "TESTING: Found student " . validatedName
                    toolTipMessage := "Found student " . validatedName
                    if (validatedTopic != "") {
                        logMessage .= ", " . validatedTopic
                        toolTipMessage .= " (" . validatedTopic . ")"
                    }
                    ; Session details will be logged via end-session CSV dialog
                    ToolTip(toolTipMessage . " waiting", 10, 50)
                    SetTimer(() => ToolTip(), -3000)
                } else {
                    logMessage := "TESTING: Found student waiting (name unclear after validation)"
                    ; Session details will be logged via end-session CSV dialog
                    ToolTip("Found student waiting", 10, 50)
                    SetTimer(() => ToolTip(), -3000)
                }
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
            
            ; Step 5: Show message box with session message
            modePrefix := LiveMode ? "Session with " : "Found student "
            if (validatedName != "") {
                MsgBox(modePrefix . validatedName . (LiveMode ? " has opened" : " waiting"), LiveMode ? "Session Started" : "Student Detected", "OK")
            } else {
                MsgBox(LiveMode ? "A session has opened" : "A student is waiting", LiveMode ? "Session Started" : "Student Detected", "OK")
            }
            
            ; Step 6: When OK is clicked, stop the sound and continue monitoring
            if (SoundTimerFunc != "") {
                SetTimer SoundTimerFunc, 0  ; Stop the timer
                SoundTimerFunc := ""
            }
            
            ; Continue monitoring for more students (removed break statement)
            }
        }
        
        ; Wait 50ms before next scan (faster detection)
        Sleep 50
        
        ; Continue monitoring (removed window existence check)
    }
    
    ; Clear tooltip when done
    ToolTip ""
}