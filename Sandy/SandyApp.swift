import SwiftUI
import UserNotifications

@main
struct SandyApp: App {
    @StateObject var webViewModel = WebViewModel()

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
        dateComponents.hour = 9 // 每天早上 9 點發送通知

        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)

        let request = UNNotificationRequest(identifier: "dailyReminder", content: content, trigger: trigger)

        center.getPendingNotificationRequests { requests in
            let today = Calendar.current.startOfDay(for: Date())
            let lastOpenDate = UserDefaults.standard.object(forKey: "lastOpenDate") as? Date ?? Date.distantPast

            // 如果今天還沒開過 App 並且沒有相同的提醒通知，則新增通知
            if lastOpenDate < today && !requests.contains(where: { $0.identifier == "dailyReminder" }) {
                center.add(request) { error in
                    if let error = error {
                        print("通知添加失敗：\(error.localizedDescription)")
                    }
                }
            }
        }
    }

    // 檢查遠端通知
    private func checkForRemoteNotification() {
        guard let url = URL(string: "https://nkust.suko.zip/notification.json") else { return }

        URLSession.shared.dataTask(with: url) { data, response, error in
            if let error = error {
                print("無法讀取遠端通知：\(error.localizedDescription)")
                return
            }

            guard let data = data else { return }

            do {
                if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                   let title = json["title"] as? String,
                   let body = json["body"] as? String,
                   let dateString = json["date"] as? String {

                    let formatter = DateFormatter()
                    formatter.dateFormat = "yyyy-MM-dd"
                    if let notificationDate = formatter.date(from: dateString) {
                        let today = Calendar.current.startOfDay(for: Date())

                        // 如果通知是今天的或最近 24 小時的，則發送推送通知
                        if notificationDate >= today.addingTimeInterval(-86400) {
                            sendCustomNotification(title: title, body: body)
                        }
                    }
                }
            } catch {
                print("JSON 解析失敗：\(error.localizedDescription)")
            }
        }.resume()
    }

    // 發送即時通知的方法
    func sendCustomNotification(title: String, body: String) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 5, repeats: false)

        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("即時通知添加失敗：\(error.localizedDescription)")
            }
        }
    }
}
