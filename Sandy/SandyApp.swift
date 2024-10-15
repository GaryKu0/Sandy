import SwiftUI
import UserNotifications

@main
struct SandyApp: App {
    @StateObject var webViewModel = WebViewModel()
    private let debug = false // 設置 debug 變數

    init() {
        requestNotificationPermission()
        scheduleDailyNotification() // 設定每日提醒通知
        checkForRemoteNotification() // 檢查遠端的通知
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(webViewModel)
                .onAppear {
                    updateLastOpenDate()
                }
        }
    }

    // 請求推送通知的權限
    private func requestNotificationPermission() {
        let center = UNUserNotificationCenter.current()
        center.requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
            if let error = error {
                print("授權失敗：\(error.localizedDescription)")
            } else if granted {
                print("通知授權成功")
            } else {
                print("使用者拒絕了通知授權")
            }
        }
    }

    // 更新應用最近一次被打開的日期
    private func updateLastOpenDate() {
        let today = Calendar.current.startOfDay(for: Date())
        UserDefaults.standard.set(today, forKey: "lastOpenDate")
    }

    // 設定每日提醒通知
    private func scheduleDailyNotification() {
        let hasScheduled = UserDefaults.standard.bool(forKey: "hasScheduledDailyNotification")
        if hasScheduled { return }

        let center = UNUserNotificationCenter.current()

        let notifications = [
            ("咀嚼大挑戰！", "今天來場咀嚼馬拉松吧！健口操等你來挑戰，讓你的下巴肌肉也能練出六塊肌。"),
            ("舌尖上的健康", "別讓你的舌頭偷懶了！來做健口操，讓你的舌頭變得靈活如體操選手。"),
            ("笑容加分時間", "想要電力十足的笑容嗎？健口操是你的秘密武器，讓你的笑容魅力無法擋！"),
            ("下巴的健身房", "今天的下巴健身時間到了！健口操讓你的下巴肌肉比巨石強森還要強壯。"),
            ("舌頭躲貓貓", "來玩舌頭躲貓貓吧！健口操讓你的舌頭靈活得像隻頑皮的小貓。"),
            ("口腔奧運會", "準備好了嗎？口腔奧運會即將開始！健口操是你奪金的最佳機會。"),
            ("開口笑大作戰", "讓我們一起用健口操，把悶悶不樂變成開懷大笑。笑口常開，健康常在！")
        ]
        let randomNotification = notifications.randomElement()!

        let content = UNMutableNotificationContent()
        content.title = randomNotification.0
        content.body = randomNotification.1
        content.sound = .default

        var dateComponents = DateComponents()
        if debug {
            let nextMinute = Calendar.current.date(byAdding: .minute, value: 1, to: Date())!
            dateComponents = Calendar.current.dateComponents([.hour, .minute], from: nextMinute)
        } else {
            dateComponents.hour = 9 // 每天早上 9 點發送通知
        }

        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)

        let request = UNNotificationRequest(identifier: "dailyReminder", content: content, trigger: trigger)

        center.add(request) { error in
            if let error = error {
                print("通知添加失敗：\(error.localizedDescription)")
            } else {
                print("每日提醒通知已成功添加")
                UserDefaults.standard.set(true, forKey: "hasScheduledDailyNotification")
            }
        }
    }

    // 檢查遠端通知
    private func checkForRemoteNotification() {
        print("checkForRemoteNotification 被呼叫")
        let randomValue = UUID().uuidString
        guard let url = URL(string: "https://nkust.suko.zip/notification.json?\(randomValue)") else {
            print("URL 無效")
            return
        }

        URLSession.shared.dataTask(with: url) { data, response, error in
            print("開始網路請求")
            
            if let error = error {
                print("無法讀取遠端通知：\(error.localizedDescription)")
                return
            }

            guard let data = data else {
                print("沒有收到任何數據")
                return
            }
            
            print("收到數據，開始解析 JSON")

            do {
                if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
                    print("JSON 解析成功：\(json)")
                    
                    guard let title = json["title"] as? String,
                          let body = json["body"] as? String,
                          let dateString = json["date"] as? String else {
                        print("JSON 格式錯誤，缺少必要的欄位")
                        return
                    }

                    let formatter = DateFormatter()
                    formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
                    
                    if let notificationDate = formatter.date(from: dateString) {
                        print("解析出的通知日期：\(notificationDate)")
                        let twentyFourHoursAgo = Date().addingTimeInterval(-86400)
                        print("24 小時前的時間：\(twentyFourHoursAgo)")

                        // 如果通知是最近 24 小時內，則發送推送通知
                        if notificationDate >= twentyFourHoursAgo {
                            print("通知日期符合條件，準備發送通知")
                            let identifier = "remoteNotification_\(notificationDate.timeIntervalSince1970)"
                            let hasSent = UserDefaults.standard.bool(forKey: identifier)
                            print("通知標識符：\(identifier)，是否已發送過：\(hasSent)")

                            if !hasSent {
                                sendCustomNotification(title: title, body: body, notificationDate: notificationDate)
                            } else {
                                print("已經發送過相同的遠端通知，不再重複發送")
                            }
                        } else {
                            print("通知日期不符合條件，不發送通知")
                        }
                    } else {
                        print("日期格式錯誤，無法解析")
                    }
                } else {
                    print("JSON 解析失敗，無法轉換為字典")
                }
            } catch {
                print("JSON 解析失敗：\(error.localizedDescription)")
            }
        }.resume()
    }

    // 發送即時通知的方法
    func sendCustomNotification(title: String, body: String, notificationDate: Date) {
        print("開始發送通知：\(title) - \(body)")
        
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 6, repeats: false)

        // 使用通知的日期作為識別符（或使用其他唯一標識）
        let identifier = "remoteNotification_\(notificationDate.timeIntervalSince1970)"
        print("通知識別符：\(identifier)")

        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("即時通知添加失敗：\(error.localizedDescription)")
            } else {
                print("通知已成功添加：\(identifier)")
                // 記錄已發送的通知
                UserDefaults.standard.set(true, forKey: identifier)
            }
        }
    }
}
