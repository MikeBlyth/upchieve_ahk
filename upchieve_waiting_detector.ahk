#Requires AutoHotkey v2.0
#Include FindTextv2.ahk
#Include alphabet.ahk
#Include student_database.ahk
#Include ahk_utilities.ahk



; Set coordinate mode to window coordinates for unified coordinate system
CoordMode("Mouse", "Window")
CoordMode("Pixel", "Window")

; Upchieve Waiting Student Detector
; Hotkeys: Ctrl+Shift+Q to quit, Ctrl+Shift+H to pause/resume, Ctrl+Shift+A to start/end session, Ctrl+Shift+S to capture screenshot, Ctrl+Shift+M to cycle modes

TargetWindow := "UPchieve"
SoundTimerFunc := ""
LiveMode := false
ScanMode := false  ; If true, just scan for students and log times, do not click
modeText := "TESTING"  ; Current mode text for display purposes

; Session tracking variables (minimal state management for manual session control)
InSession := false  ; Track if currently in an active session
LastStudentName := ""
LastStudentTopic := ""  ; Subject from pattern matching
LastRawStudentName := ""  ; Original OCR result for student name
SessionStartTime := ""
SessionEndTime := ""

; Scan timing variables
ScanTimes := []
ScanCount := 0

; Session end detection timing
lastSessionEndCheck := 0

; Search statistics tracking
SearchStats := SearchStatsClass()

; Function to play notification sound
PlayNotificationSound() {
    SoundBeep(800, 500)  ; 800Hz beep for 500ms
}

WaitingTarget1 := "|<Waiting>*150$65.00000000000000000s0000000003k000000000DU000000E01z0000003U0Di000000T00QQ006C07s000s00Bw0z0001k00TU7s0003U00w0y00007001k3k0000C003U600000Q0070D00000s00A0DU0001k00M07k0003U00k03s0007001U01y000C003000z000Q006000S000s00A000A001k00M0000003U00k00000000000E"
WaitingTarget2 := "|<Waiting>*151$86.00000000000000000000600000000000003U0000000000003s0000000000U03y0000000000s01tU000000000y00QM00CTUz000z0006003jwTs00y0001U00z7i700y0000M00DUT0s1y00006003k7UC0y00001U00s1k1UC00000M00C0Q0M3k00006003U7060T00001U00s1k1U1y0000M00C0Q0M07s0006003U70600TU001U00s1k1U00y000M00C0Q0M003U006003U7060008001U00s1k1U000000M00C0Q0M00000000000000000000000000000U"
WaitingTarget3 := "|<Waiting>*152$38.000001k00000w00000T00400Tk0700TQ07k0770Dk001kDk000QDk0007DU0001rU0000RU00007S00001ns0000QDU00070y0001k3w000Q0Dk00700w001k03000Q0000070000008"
WaitingTarget4 := "|<Waiting1>**50$41.0000000000001k000007U00000R000k03y007U0Tw00z00Qs07s001k1z0003UDk00071y0000C7k0000QC00000sT00001kTU0003UDk000707s000C03w000Q01y000s00y001k00A003U0000070000000E"

WaitingTarget := WaitingTarget3 . WaitingTarget4

; Using "New" is a workaround for the first two targets not being found for unknown reasons
UpgradeTarget := "|<Upgrade>*196$93.zzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzwTwQ03zk3y03zzzzXzXU07w0Dk07zzzwTwQDUz1Uy7UTzzzXzXVz3kz3kz3zzzwTwQDwQDwS7wTzzzXzXVzVVzVkzVzzzwTwQDwATzy7wDzzzXzXVzXXzzkzXzzzwTwQDsQTzy7sTzzzXzXVy3Xzzky3zzzwTwQ00wT0C00zzzzXzXU0TXs1k0TzzzwTwQDzwTwC7XzzzzXzXVzzXzVkwDzzzwDwQDzwDwC7lzzzzVz3VzzlzVky7zzzy7sQDzy7wC7sTzzzkQ7VzzsC1kz3zzzz01wDzzU0y7wDzzzy0zVzzz0Dkzkzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzw"
               . "|<UpgradeGray2Two_wide>*230$137.00M001zzzzzzzzzzzzzzzzy00k007zzzzzzzzzzzzzzzzw00U00Dzzzzzzzzzzzzzzzzs01U00Tzzzzzzztzls0TzUTk03000zzzzzzzznzXk0Dw0DU02003zzzzzzzzbz7bwDkwD004007zzzzzzzzDyDDyD7yS00800DzzzzzzzyTwSTwSDwQ00M00Tzzzzzzzwzswzwwzws00k00zzzzzzzztzltztlzzk01U01zzzzzzzznzXnzXXzzU03003zzzzzzzzbz7bz77zz006007zzzzzzzzDyDDwSDzy00A00DzzzzzzzyTwS01wT0Q00M00Tzzzzzzzwzsw07sy0s00k00zzzzzzzztzltzzlztk01U01zzzzzzzznzXnzzXznU03003zzzzzzzzbz7bzzbzb004007zzzzzzzzDyTDzz7zC00800DzzzzzzzyDsyTzz7yQ00E00TzzzzzzzyDXwzzy7ks01U00Tzzzzzzzy0Dtzzy03k03000zzzzzzzzz0znzzz0TU04001zzzzzzzzzzzzzzzzz00M003zzzzzzzzzzzzzzzzz"
               . "|<New>*134$76.7U07U00000000T00S000000001y01s000000007s07U00000000Tk0S000000001zU1s000000007y07U00000000Tw0S01y0Q0Q0Fvk1s0Ty1s1s17bU7U3zw7U7U4SD0S0S3sC0y0Fsw1s3k7Us3w37Vs7US0C3kDkAS7kS1s0w71r0lsD1s703kQ7Q37US7UQ071kQsQS1wS3zzw7VXVls3lsDzzkCCC77U7bUzzz0ssQQS0TS3k003XVnVs0xsD000DQ7C7U1zUQ000RkCsS07y1s001z0vVs0Ds7U007s3w7U0zUD0C0DU7kS01y0z1s0y0T1s03s1zzU3k1s7U0DU1zs0D07US00S01y00Q0C00000000000000000000000002"
 

StudentHeaderTarget := "|<StudentHeader>*146$71.00000000000000000000001w3z00k000003sTzUDU000007nzzkT000000Djzzky000000TTUT1w000000yy0QTznw7k3txw0EzzbsDUTvvy01zzDkT1zzrzk3zyTUy3zzjzw0y0z1wDkzDzy1w1y3sT0yDzy3s3w7ky1w3zw7k7sDVw3s0TsDUDkT3s7m0DkT0TUy7kDa0DUy0z1wDUTT0z1w1y7sTVzzzy3zlzzkzzxzzs7zXzzUzztzzU7z3zD0znkTs03w3wS0T7U00000000000000000000001"

FinishTarget :="|<Finish>*225$127.01000000000000000000001U00000000000000000001U00000000000000000000U00000000000000000000k00000000000000000000E00000000000000000000E00000000000000000000M00000000000000000000800000000000000000000400000000000000000000400000000000000000000200000000000000000000300000000000000000000100000000000T0000w0000U0000000000DU000z0000E0000000Dzz7k000TU000M00000007zzXk0007U000800000003zzk000000000400000001s00000000000200000000w00000000000100000000S00D1tz0S0zk0U0000000D007UzzkD0zy0k00000007U03kTzw7Uzz0M00000003k01sDky3ky7kA00000001zz0w7kD1sS1k600000000zzkS3s7kwDU0300000000TzsD1s3sS7y01U0000000D007Uw1wD1zs0E00000007U03kS0y7UTz0800000003k01sD0T3k1zk400000001s00w7UDVs03s200000000w00S3k7kw60w100000000S00D1s3sS7Uy0k0000000D007Uw1wD3zz0800000007U03kS0y7Uzz0400000003k01sD0T3k7y02000000000000000000001U00000000000000000000E000000000000000000008000000000000000000002000000000000000000001000000000000000000000k0000000000000000000E"
EndSessionTarget :="|<EndSession>*194$193.00C0000000000000000000000000000000C0000000000000000000000000000000C0000000000000000000000000000000C0000000000000000000000000000000C000000000000000000000000000000060000000000000000000000000000000600000000000000000000000000000007000000000000000000000000000000030000000000000000000000000000000300000000000000000000000000000003U0000000000000000000000000000001U0000000000000000000000000000000k0000000000000000000000000000000k0000000000000000000000000000000M0000000000000000000000000000000Q0000000000000000000000000000000A000000000000000000000000000000060000000000000000S0000000000000070000000000000000D00000000000000300000000zzw000007U007w0000000001U0000000Tzy000003k00DzU000000000k0000000Dzz000001s00Dzs000000000s00000007U0000000w00D0S000000000M00000003k0000000S00D07000000000A00000001s00STU0zD007U103w03w0Ds600000000w00DTs0zzU03k007zU7zUTz300000000S007zy0zzk01w007zs7zsDzlU0000000D003w7Uw3s00zU07US7UQD1sk00000007zw1w3kS0w00DzU3U73k470MM00000003zy0w0sS0S003zw3k3Vs03k0A00000001zz0S0QD0D000TzVzzkzU1y0600000000w00D0C7U7U000zkzzsDz0Tw300000000S007U73k3k0001wTzw1zk3zVU0000000D003k3Vs1s0000SD0007w0Dsk00000007U01s1kw0w0080D7U000D00wQ00000003k00w0sD0S00C07Vs20U7V0C600000001s00S0Q7UT007k7Uw3ks3lkD300000000zzwD0C1zzU01zzUDzkTzkzzVU0000000Tzy7U70Txk00TzU3zk7zkDzUs0000000Dzz3k3U7ss003z00Tk0zU1z0A0000000000000000000000000000000600000000000000000000000000000003U0000000000000000000000000000000k0000000000000000000000000000000M000000000000000000000000000000060000000000000000000000000000000300000000000000000000000000000001k0000000000000000000000000000000M0000000000000000000000000000000600000000000000000000000000000003U0000000000000000000000000000000k0000000000000000000000000000000A0000000000000000000000000000000700000000000000000000000000000001k0000000000000000000000000000000Q0000000000000000000000000000000700000000000000000000000000000001k0000000000000000000000000000000Q0000000000000000000000000000000700000000000000000000000000000001s0000000000000000000000000000E"
SessionEndedTarget := "<SessionEnded>*195$237.zzzzzzzzzzzzs7zzzzzzzzzzzzzzzzsDzzzzz1zzs0zzzzzzzzzz0zzzzzzzzzzzzzzzzz1zzzzzsDzw01zzzzzzzzzs7zzzzzzzzzzzzzzzzsDzzzzz1zz007zzzzzzzzzVzzzzzzzzzzzzzzzzz1zzzzzsDzk30TzzzzzzzzzzzzzzzzzzzzzzzzzzsDzzzzz1zy3y3zzzzzzzzzzzzzzzzzzzzzzzzzzz1zzzzzsDzkTszk3zk3zU7wDw0zkk7zzy0Tks7zUMDw1zw31zy3zjw07s07k0DVy01y40Tzz01y00Tk01y03y00DzkDzy00S00Q00wDU07k01zzk07k01w00DU0DU01zy07zkA3kA3UM7Vw30y0kDzy1US0EDU81s20w30Dzk03w7sC3sw7lwD0y3kD1zzUz3kD0s7kD1w70y1zz00DUz1kTjUzTVsDkS3s7zw7sC3w71y1kTksDkDzy00Q00C0Dw0TwD1z3kTUzzU01kTUsDsC0071z1zzw03U01s0Dk0TVsDsC3w7zw00C3w71z1k00sDsDzzz0Q00DU0z01wD1z1kTUzzU01kTUsDsC0071z1zzzy1Uzzz03y07VsDsS3w7zw7zy3w71z1kTzsDsDztzkA7zzzUTz0wD1y3kTUzzUzzkTUsDkC3zz1y1zy7y3UT3tz1ny3Vs7kS3w7zw3sy3w70y1sDVs7kDzU70S0UC1UQ30wDUM7kTUzzkA3kTUw10D0M7UM1zy007s03k03U07Vw00y3w7zy00S3w7U01w01w00Dzs01zU0z00y01wDk0DkTUzzs07kTUy08Dk0Tk11zzk0zy0Tw0Ts0zVzU7y3w7zzk3y3w7w31zU7zUMDzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzU" .
                      "|<SessionEnded>*194$133.zzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzz3zzzzzzzzzzzzzzzzy3zzz0zzzzzzzzzzzzzzzzz1zzzUTzzzzzzzzzzzzzzzzUzzzkDzzzzzzzzzzzzzzzzkTzzwDzzzzzzzzzzzzzzzzsDzzzzzzzzzzzzzzzzzzzzw7zzzzzzzzzzzzzzzzzzzzy3w0zVzU7y60zzzk3y70zw31s07kz00z20DzzU0T00Ds00s01sT00DU03zzU0DU03s00Q30wDUM7k61zzkA3k21w10C3sy7UT1s7UzzkTVs7UQ3s71yz3kTUw7kDzsDkQ7sC3w3U3zVsDsS3w7zw00C3w71z1s0Dkw7w71y3zy0071y3UzUy03sS3y3Uz1zz003Uz1kTkTk0wD1z3kTUzzUzzkTUsDsDzUS7Uz1sDkTzkTzsDkQ7s7bw73kDUw7sDzs7lw7sC1w3UM7Vw30y3w7zy1US3w7U81k03ky00T1y3zz00D1y3k00w03sTU0TUz1zzk0DUz1w0ET07wDw0zkTUzzy0TkTUzUMDzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzw"


PencilTipTarget :="|<PencilTip>**50$69.000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001zs000000007w3y0000000DU00T0000007U000S000003U0000Q00001k00k00s0000Q00D003U000C001w0070003U00Nk00Q000k0076000k00A001ks003003000A3U00A00k003UA000k0A000ryk00303000Dzz000A0M001k0Q001U6000Q01U0061U00700C000MA000k00s0033000C003U00AE003U00A000a000s001k006U0060007000I001k000Q003U00Q0003U00M0070000C001000k0000s00800C00003001003U0000Q00000s00001k0000600000700001k00000M0000Q000003U0007000000C0000s000000s000C0M0k1U3U001k7UD0C0Q000D0y1w3s7U001wCsRkvVw000BnXb7CCTU001bsDkTUzQ000Ay0w1s3nU001XU3U70CQ000A8080E0XU001U000000Q04"

SubjectTargets := 
    "|<6th Grade Math>*151$53.000000s000TU001k003zU3U3U00D7U707000s3UC0C003U30Q0Q007007zsty0A00Dzlzy0s003U3wS1ly0707US3jz0C0C0Q7sD0Q0Q0sDUC0s0s1kS0C1k1k3Uw0Q3U3U70s0s7070C1k1kC0C0Q3U30Q0Q0s3UC0s0s1k3ls1tVk3U3zU1zXU701y01w70C000000000E" .
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

BlockedTargets := "|<Chukwudi>**50$108.0Dw0Q000001k0000000zz0Q000001k0000001yDUQ000001k0000003k3kQ000001k0000003U1sQ000001k0000007U0UQz070C1k7b0C0Q7000Rzk70C1kD7UD0Q7000Tns70C1kS3UP0wD000T0s70C1kw3UT0sC000S0s70C1ls1kTUsC000Q0w70C1nk1kvVsC000Q0Q70C1rU1kvVkD000Q0Q70C1zk0sllk7000Q0Q70C1zk0tlnU7000Q0Q70C1Rs0tknU7U0sQ0Q70C1sw0NUvU3U1sQ0Q70S1kQ0RUv03k3kQ0Q70S1kS0TUT01yDUQ0Q7ly1kD0D0T00zz0Q0Q3zy1k70D0S00Dw0Q0Q0zC1k3UD0C0000000000000000000U"
    . "|<Chukwudi>*150$111.0000Q000001U00000000zU3U00000A00000000Tz0Q000001U0000000DUw3U00000A00000001k3kQ000001U0000000Q0C3U00000A0000000700UQz060C1U770C0Q8s003jy0k1kA1kQ1k3V7000TXk60C1UQ3UD0M8k003k70k1kA70Q3s71C000S0s60C1Vk1UP0s9k003U30k1kAQ0C3Q61C000Q0M60C1bU1ktVk8k003U30k1kBy066AC17000Q0M60C1zk0sllU8s003U30k1kD707C6Q1700sQ0M60C1kw0NUnU8Q0C3U30s1kA3U3g7M11k3kQ0M70S1UC0D0T08DVw3U30QDkA1s1s3s00Tz0Q0M3zi1U70D0C000zU3U307tkA0Q0k1k00000000000000000000000000000000000000U"
    . "|<Camila>*130$106.000000000000000000000000000000s60000000000000003kM00003w000000000D1U0000zw000000000s60000DVw0000000000M0001s1k0000000001U000703U00000000060000s000TU37kDU3UM0TU3U007z0BznzU61U3zUQ000wC0y7yD0M60QD1k0070Q3kDUQ3UM3UA700081kC0Q0s61U40sQ000070s1k3UM6003Vk0000Q3U70C1UM00S70001zkA0Q0s61U0zsQ000Tz0k1k3UM60DzUk003kQ3070C1UM1sC3U0MQ1kC0Q0s61UC0s703VU70k1k3UM60k3US0Q70w3070C1UM30S0y7kQ7kA0Q0s61kC3s0zw0zvks1k3UM7sTxk0z00y73070C1U7Uz70000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000002"
    . "|<Solis>*151$81.0000000000000000000000000000000000Q1k00000000003US00000Tk0000Q3k0000DzU0003UC00003kS0000Q000000s0s0003U000007030000Q000000k0E0zU3UC0TU07000Dz0Q1kDz00s007lw3UC3kw07k00s3UQ1kQ3U0Ts0C0C3UC30800zw1k1kQ1kQ0001zkC063UC3s0000T1U0kQ1kDw0000wA063UC0Ts0003Vk0kQ1k0DU0U0QC0C3UC00C0C03Vk1kQ1k01k1s0s70Q3UC70A07kT0yDUQ1kS7U0Dzk1zs1yC1zs00Tk07w07Vk3w00000000000000000000000000004"
; Debug log function

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
    global StudentHeaderTarget, targetWindowID

    ; Track previous header position to only log changes
    static prevStudentPos := {x: -1, y: -1}

    while (true) {
        ; Initialize header position (will be empty if not found)
        global studentHeaderPos := {x: 0, y: 0, found: false}

        ; Define search zones for Student Header
        studentZone1 := SearchZone(600, 1150, 900, 1250)
        studentZone2 := SearchZone(0, 150, 0, 2000, 1800, 0)   ; Wider fallback zone

        ; Search for Student Header (non-verbose)
        if (result := FindTextInZones(StudentHeaderTarget, studentZone1, studentZone2, 0.15, 0.10, &SearchStats, false)) {
            upperLeft := GetUpperLeft(result)
            studentHeaderPos := {x: upperLeft.x, y: upperLeft.y, found: true}
        }

        ; Check if Student header found
        if (studentHeaderPos.found) {
            ; Log header position if it changed
            if (studentHeaderPos.x != prevStudentPos.x || studentHeaderPos.y != prevStudentPos.y) {
                WriteLog("Student header found at " . studentHeaderPos.x . "," . studentHeaderPos.y)
                ; Update previous position after logging
                prevStudentPos.x := studentHeaderPos.x
                prevStudentPos.y := studentHeaderPos.y
            }
            ; Student header found - return successfully
            return
        } else {
            ; Missing Student header - show simple message box
            result := MsgBox("Missing Student column header. Please adjust the browser window to ensure the Student column header is visible, then click OK to retry.", "Missing Student Header", "1 4096")  ; OK/Cancel
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
    blockingZone := SearchZone(studentHeaderPos.x - 5, studentHeaderPos.y + 95, 0, 0, 300, 40)


    ; Search for blocked patterns in calculated zone
    if (result := FindTextInZones(BlockedTargets, blockingZone, "", 0.15, 0.15, &SearchStats)) {
        ; Found a blocked name pattern
        blockedName := result[1].id  ; Get the pattern name (e.g. "Chukwudi", "Camila")
        WriteLog("BLOCKED: " . blockedName)

        ; Show message box notification
;        MsgBox("Blocked student detected: " . blockedName, "Student Blocked", "OK Iconi 4096")

        return {blocked: true, name: blockedName}
    }

    ; No blocked patterns found
    WriteLog("DEBUG: No blocked patterns found in zone " . blockingZone.ToString())
    return {blocked: false, name: ""}
}

; Handle session after student is detected or manually started
HandleSession(waitingX := 0, waitingY := 0, detectionStartTime := 0, studentDetectionCount := 0, isManual := false) {
    global LiveMode, targetWindowID, LastStudentName, LastStudentTopic, LastRawStudentName, SessionStartTime, SoundTimerFunc

    ; Skip automated steps for manual sessions (user already clicked and activated window)
    if (!isManual) {
        ; Step 1: Activate window immediately (parallel with extraction)
        WinActivate("ahk_id " . targetWindowID)

        ; Step 2: Extract topic using fast pattern detection (no OCR)
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

            ; Update session tracking variables (no name, subject only)
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
            try {
                WinGetPos(&activeX, &activeY, , , "A")
            } catch {
                ; Fallback if no active window (rare edge case)
                activeX := 100
                activeY := 100
            }
            CoordMode "ToolTip", "Screen"
            ToolTip "📚 In session" . (LastStudentTopic ? " (" . LastStudentTopic . ")" : ""), activeX + 100, activeY + 100, 1
        } else {
            ; TESTING mode - no name extraction
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
            try {
                WinGetPos(&activeX, &activeY, , , "A")
            } catch {
                ; Fallback if no active window (rare edge case)
                activeX := 100
                activeY := 100
            }
            CoordMode "ToolTip", "Screen"
            ToolTip "🧪 Testing mode - student detected" . (LastStudentTopic ? " (" . LastStudentTopic . ")" : ""), activeX + 100, activeY + 100, 1
        }

        ; Step 4: Start repeating notification sound (every 2 seconds)
        PlayNotificationSound()  ; Play immediately
        SoundTimerFunc := PlayNotificationSound  ; Store function reference
        SetTimer SoundTimerFunc, 2000  ; Then every 2 seconds

        ToolTip ""  ; Clear tooltip
    } else {
        ; Manual session - initialize variables for session start dialog
        WriteLog("Manual session started via Ctrl+Shift+A")
        LastRawStudentName := ""  ; Manual entry required
        LastStudentName := ""  ; Manual entry required
        LastStudentTopic := ""  ; Manual entry required
        SessionStartTime := A_Now
    }

    ; Step 5: Show session start dialog for name and subject entry
    global InSession
    InSession := true  ; Mark that we're now in a session
    dialogResult := ShowSessionStartDialog()

    ; Step 6: Stop the sound and handle dialog result
    if (SoundTimerFunc != "") {
        SetTimer SoundTimerFunc, 0  ; Stop the timer
        SoundTimerFunc := ""
    }

    ; Step 7: Monitor for session end
    MonitorSessionEnd()

    ; Step 8: Show session feedback dialog
    InSession := false  ; Session has ended
    continueResult := ShowSessionFeedbackDialog()

    if (continueResult = "Restart") {
        WriteLog("DEBUG: Session ended - restarting script")
        Reload
    } else if (continueResult = "No") {
        CleanExit()
    } else {  ; Cancel (Pause) - simplified flow continues after pause
        SuspendDetection()
        WriteLog("DEBUG: Resuming after pause, returning to wait loop")
    }
}

; Monitor for session end in a dedicated loop
MonitorSessionEnd() {
    global targetWindowID, InSession, SessionEndedTarget

    ; Monitor for session end
    WriteLog("DEBUG: Starting session end monitoring")

    while (InSession) {  ; Check InSession instead of infinite loop
        sessionEndZone := SearchZone(3000-822, 320, 3000, 485)
        
        if (tempResult := FindTextInZones(SessionEndedTarget, sessionEndZone,, 0.15, 0.10, &SearchStats)) {
            WriteLog("DEBUG: SessionEndedTarget found at " . tempResult[1].x . "," . tempResult[1].y)
            break
        }

        Sleep 1000  ; Check every 2 seconds
    }
    WriteLog("DEBUG: Session end monitoring stopped")
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
    global studentHeaderPos, SubjectTargets, SubjectTargets_2, targetWindowID

    ; Define primary zone: x+150, y+95, 200x40 from StudentHeader upper-left
    primaryZone := SearchZone(studentHeaderPos.x + 150, studentHeaderPos.y + 95, 0, 0, 200, 40)

    ; Try primary zone with SubjectTargets
    if (result := FindTextInZones(SubjectTargets, primaryZone, "", 0.15, 0.10, &SearchStats)) {
        WriteLog("DEBUG: Subject: found=" . result[1].id . " searchTime=" . SearchStats.searchTimeMs . "ms foundInZone=" . SearchStats.foundInZone)
        return result[1].id
    }

    ; Define secondary zone: x+215, y+95, 135x40 from StudentHeader upper-left (wider coverage)
    secondaryZone := SearchZone(studentHeaderPos.x + 215, studentHeaderPos.y + 95, 0, 0, 135, 40)

    ; Try secondary zone with SubjectTargets_2
    if (result := FindTextInZones(SubjectTargets_2, secondaryZone, "", 0.15, 0.10, &SearchStats)) {
        WriteLog("DEBUG: Secondary Subject Zone - SUCCESS: found=" . result[1].id . " searchTime=" . SearchStats.searchTimeMs . "ms foundInZone=" . SearchStats.foundInZone)
        return result[1].id
    }

    ; No subject pattern matched - return empty string for manual entry
    return ""
}

;
; Cycle between LIVE/TESTING/SCAN modes during runtime
CycleModes() {
    global LiveMode, ScanMode, modeText

    ; Debug: Log current state before change
    WriteLog("DEBUG: Before mode change - LiveMode=" . LiveMode . " ScanMode=" . ScanMode . " modeText='" . modeText . "'")

    ; Cycle through modes: LIVE -> TESTING -> SCAN -> LIVE
    if (LiveMode) {
        ; Currently LIVE -> switch to TESTING
        LiveMode := false
        ScanMode := false
        modeText := "TESTING"
    } else if (!ScanMode) {
        ; Currently TESTING -> switch to SCAN
        LiveMode := false
        ScanMode := true
        modeText := "SCAN"
    } else {
        ; Currently SCAN -> switch to LIVE
        LiveMode := true
        ScanMode := false
        modeText := "LIVE"
    }

    ; Debug: Log current state after change
    WriteLog("DEBUG: After mode change - LiveMode=" . LiveMode . " ScanMode=" . ScanMode . " modeText='" . modeText . "'")

    ; Show brief notification of mode change and update main tooltip
    try {
        WinGetPos(&activeX, &activeY, , , "A")
    } catch {
        activeX := 100
        activeY := 100
    }
    CoordMode "ToolTip", "Screen"

    ; Update main tooltip (tooltip #1) to reflect new mode immediately
    ToolTip "⏳ Waiting for students... (" . modeText . " mode)", activeX + 100, activeY + 100, 1

    ; Show mode change notification (tooltip #2)
    ToolTip "🔄 Mode switched to: " . modeText, activeX + 100, activeY + 150, 2
    SetTimer () => ToolTip("", , , 2), -3000  ; Clear mode notification after 3 seconds

    WriteLog("Mode switched to: " . modeText)
}

; Suspend detection with resume option
SuspendDetection() {
    ; Simple pause dialog - no state management needed in simplified flow
    MsgBox("Upchieve suspended`n`nPress OK to resume", "Detection Paused", "OK")
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
    global LastStudentName, LastStudentTopic, LastRawStudentName, SessionStartTime, InSession
    WriteLog("DEBUG: Manual EndSession() called")

    ; Mark that we're no longer in a session
    InSession := false

    ; Always show session feedback dialog when called manually
    continueResult := ShowSessionFeedbackDialog()

    if (continueResult = "Restart") {
        WriteLog("Manual session end - restarting script")
        Reload
    } else if (continueResult = "No") {
        CleanExit()
    } else {  ; Cancel (Pause)
        SuspendDetection()
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
; Ctrl+Shift+A: Dual functionality - start session when waiting, end session when active
^+a::{
    global InSession
    WriteLog("DEBUG: Ctrl+Shift+A hotkey triggered")

    if (InSession) {
        ; Currently in session - end it
        WriteLog("Ending current session")
        EndSession()
    } else {
        ; Not in session - start manual session (user already clicked student)
        WriteLog("Starting manual session")
        HandleSession(0, 0, 0, 0, true)  ; isManual = true
    }
}
; Ctrl+Shift+S: Manual screenshot capture
^+s::{
    WriteLog("DEBUG: Ctrl+Shift+S hotkey triggered")
    if (CaptureDetectionScreenshot()) {
        ToolTip "Screenshot captured successfully", 10, 10, 1
        SetTimer () => ToolTip("", , , 1), -2000  ; Clear tooltip after 2 seconds
    } else {
        ToolTip "Screenshot capture failed", 10, 10, 1
        SetTimer () => ToolTip("", , , 1), -2000  ; Clear tooltip after 2 seconds
    }
}
; Ctrl+Shift+M: Cycle between LIVE/TESTING/SCAN modes
^+m::CycleModes()

; Global variables for OCR training screenshots
TempScreenshotPath := ""
SessionCounter := 0

; Capture detection screenshot from StudentHeaderPos-(5,5) to waitingTarget+(10,10)
CaptureDetectionScreenshot(waitingX := 0, waitingY := 0) {
    global studentHeaderPos, SessionCounter, TempScreenshotPath

    if (!studentHeaderPos.found) {
        WriteLog("ERROR: Cannot capture screenshot - Student header not found")
        return false
    }

    ; Calculate capture coordinates
    captureX1 := studentHeaderPos.x - 5
    captureY1 := studentHeaderPos.y - 5
    captureX2 := studentHeaderPos.x + 900
    captureY2 := studentHeaderPos.y + 132

    ; Generate temp filename
    SessionCounter++
    timestamp := FormatTime(A_Now, "yyyyMMdd_HHmmss")
    tempFilename := "temp_detection_" . timestamp . "_" . Format("{:03d}", SessionCounter) . ".bmp"

    try {
        FindText().SavePic(tempFilename, captureX1, captureY1, captureX2, captureY2, 1)
        TempScreenshotPath := tempFilename  ; Store for later rename
        WriteLog("DEBUG: Detection screenshot captured: " . tempFilename)
        return true
    } catch Error as e {
        WriteLog("ERROR: Failed to save detection screenshot - " . e.message)
        return false
    }
}

; Capture screenshot of student name region for OCR training
CaptureNameRegion(headerPos) {
    global TempScreenshotPath, SessionCounter, targetWindowID

    ; Calculate name region coordinates from header position
    searchX := headerPos.x - 5
    searchY := headerPos.y + 95
    searchWidth := 200
    searchHeight := 35
    
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
            WriteLog("DEBUG: Name region screenshot captured: " . tempFilename)
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

    ; Combined startup dialog with mode selection
    modeResult := MsgBox("Upchieve detector will search for 'Waiting Students' page and start monitoring automatically.`n`nSelect mode, then click OK and immediately click in the UPchieve browser window to identify it.`n`nYes = LIVE mode (clicks students)`nNo = TESTING mode (no clicking)`nCancel = Exit", "Upchieve Detector - Select Mode & Click Window", "YNC Default2 4096")
    if (modeResult = "Cancel") {
        CleanExit()  ; Exit application
    }
    
    LiveMode := (modeResult = "Yes")

    ; If testing mode selected, ask about scan mode
    if (!LiveMode) {
        scanResult := MsgBox("You selected TESTING mode.`n`nDo you want to enable SCAN mode?`n`nYes = SCAN mode (scan for students and log times, no clicking)`nNo = TESTING mode (standard testing behavior)", "Scan Mode Selection", "YN 4096")
        ScanMode := (scanResult = "Yes")
        modeText := ScanMode ? "SCAN" : "TESTING"
    } else {
        ScanMode := false  ; Live mode doesn't use scan mode
        modeText := "LIVE"
    }

    ; Get target window using utility function
    global targetWindowID := GetTargetWindow("Click on the UPchieve browser window now...", false)
    if (targetWindowID = "") {
        CleanExit()  ; Exit if user cancelled window selection
    }
    
    ; Wait for students loop - simplified flow
    while (true) {
        ; Step 1: Check for upgrade popups
        ToolTip "⏳ Checking for upgrade ... (" . modeText . " mode)",,, 1

        if (CheckUpgradePopups()) {
            WriteLog("DEBUG: Dismissed upgrade popup")
        }

        ; Step 2: Find headers - required each iteration
        ; Get active window position for tooltip
        ToolTip "⏳ Finding headers ... (" . modeText . " mode)",,, 1
        try {
            WinGetPos(&activeX, &activeY, , , "A")
        } catch {
            ; Fallback if no active window (rare edge case)
            activeX := 100
            activeY := 100
        }
        CoordMode "ToolTip", "Screen"
        ToolTip "🔍 Searching for headers...", activeX + 100, activeY + 100, 1
        FindHeaders()

        ; Step 3: Calculate search zones based on header positions
        WinGetClientPos(, , &winWidth, &winHeight, targetWindowID)

        ; Use precise header-based positioning: x+425, y+92, 475x40 from StudentHeader upper-left
        waitingZone1 := SearchZone(studentHeaderPos.x + 425, studentHeaderPos.y + 92, studentHeaderPos.x + 900, studentHeaderPos.y + 132)
; WriteLog("DEBUG: Waiting zone 1: " . waitingZone1.x1 . "," . waitingZone1.y1 . " to " . waitingZone1.x2 . "," . waitingZone1.y2)

        ; Step 4: Wait for students (60 seconds)
        try {
            WinGetPos(&activeX, &activeY, , , "A")
        } catch {
            ; Fallback if no active window (rare edge case)
            activeX := 100
            activeY := 100
        }
        CoordMode "ToolTip", "Screen"
        ToolTip "⏳ Waiting for students... (" . modeText . " mode)", activeX + 100, activeY + 100, 1
        result := FindText(&waitingX:='wait', &waitingY:=60, waitingZone1.x1, waitingZone1.y1, waitingZone1.x2, waitingZone1.y2, 0.15, 0.15, WaitingTarget)
;        result := FindText(, , 600,400,1500,1800, 0.15, 0.15, WaitingTarget)

        ; Step 5: If waiting student found, check if blocked and exit loop
        if (result) {
            ToolTip "⏳ Waiting target found... (" . modeText . " mode)", activeX + 100, activeY + 100, 1
            static studentDetectionCount := 0
            studentDetectionCount++
            detectionStartTime := A_TickCount
            WriteLog("DETECTION #" . studentDetectionCount . ": WaitingTarget found at " . waitingX . "," . waitingY)

            ; Capture detection screenshot
            CaptureDetectionScreenshot(waitingX, waitingY)

            ; Check for blocked name patterns FIRST (fast visual detection)
            blockResult := CheckBlockedNamePatterns()
            if (blockResult.blocked) {
                WriteLog("BLOCKED: Pattern detected - " . blockResult.name . " - skipping student")
                continue  ; Skip this student entirely, continue waiting
            }
            if (ScanMode) {
                finished := FindText(&waitingX:='wait0', &waitingY:=6000, waitingZone1.x1, waitingZone1.y1, waitingZone1.x2, waitingZone1.y2, 0.15, 0.15, WaitingTarget)
                finishedTick := A_TickCount
                ToolTip "⏳ Waiting target gone ... (" . modeText . " mode)", activeX + 100, activeY + 100, 1
                WriteLog("SCAN MODE: Student detected, " . ExtractTopic() . ", duration = " . (finishedTick - detectionStartTime) . " ms", 'scan.log')
                continue  ; In SCAN mode, do not click, just continue waiting
            }

            ; Student found and not blocked - exit wait loop to handle session
            break
        }

        ; No student found in 60 seconds - continue loop (no sleep needed)
    }

    ; Handle the session
    HandleSession(waitingX, waitingY, detectionStartTime, studentDetectionCount)
    
    ; Clear tooltip when done
    ToolTip ""
}