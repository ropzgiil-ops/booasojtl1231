import SwiftUI

struct WorkoutSet: Identifiable, Codable {
    var id = UUID()
    var weight: Double
    var reps: Int
    var isCompleted: Bool = false
    
    var oneRepMax: Double {
        guard reps > 0 else { return 0 }
        return weight * (1.0 + Double(reps) / 30.0)
    }
}

struct Exercise: Identifiable, Codable {
    var id = UUID()
    var name: String
    var muscleGroup: String
    var sets: [WorkoutSet]
}

struct CompletedWorkout: Identifiable, Codable {
    var id = UUID()
    var title: String
    var date: Date
    var totalVolume: Double
    var totalSets: Int
}

struct PersonalRecord: Identifiable, Codable {
    var id = UUID()
    var exerciseName: String
    var weight: Double
    var date: Date
}

struct ChatMessage: Identifiable, Codable {
    var id = UUID()
    var sender: String
    var text: String
    var time: String
}

class WorkoutStore: ObservableObject {
    @Published var activeExercises: [Exercise] = []
    @Published var isWorkoutActive: Bool = false
    @Published var workoutTimerSeconds: Int = 0
    @Published var restTimerSeconds: Int = 0
    @Published var isRestTimerRunning: Bool = false
    
    @Published var history: [CompletedWorkout] = []
    @Published var records: [PersonalRecord] = []
    @Published var chatMessages: [ChatMessage] = []
    
    private var timer: Timer?
    
    init() {
        loadData()
        if chatMessages.isEmpty {
            chatMessages.append(ChatMessage(
                sender: "coach",
                text: "Привет, атлет! Я IronCoach. Твой сплит верхнего тела готов к работе. Задавай любой вопрос по технике, весам или питанию!",
                time: "Сейчас"
            ))
        }
    }
    
    func startWorkout(title: String) {
        activeExercises = defaultExercises(for: title)
        isWorkoutActive = true
        workoutTimerSeconds = 0
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            self.workoutTimerSeconds += 1
            if self.isRestTimerRunning && self.restTimerSeconds > 0 {
                self.restTimerSeconds -= 1
                if self.restTimerSeconds == 0 {
                    self.isRestTimerRunning = false
                    let generator = UINotificationFeedbackGenerator()
                    generator.notificationOccurred(.success)
                }
            }
        }
    }
    
    func finishWorkout() {
        var volume: Double = 0
        var completedSets = 0
        
        for ex in activeExercises {
            for set in ex.sets where set.isCompleted {
                volume += set.weight * Double(set.reps)
                completedSets += 1
                
                let current1RM = set.oneRepMax
                if let idx = records.firstIndex(where: { $0.exerciseName == ex.name }) {
                    if current1RM > records[idx].weight {
                        records[idx].weight = current1RM
                        records[idx].date = Date()
                    }
                } else if set.weight > 0 {
                    records.append(PersonalRecord(exerciseName: ex.name, weight: current1RM, date: Date()))
                }
            }
        }
        
        let completed = CompletedWorkout(
            title: "Тренировка сплита",
            date: Date(),
            totalVolume: volume,
            totalSets: completedSets
        )
        history.insert(completed, at: 0)
        isWorkoutActive = false
        timer?.invalidate()
        timer = nil
        saveData()
    }
    
    func startRestTimer(seconds: Int = 90) {
        restTimerSeconds = seconds
        isRestTimerRunning = true
    }
    
    func addSet(to exerciseID: UUID) {
        guard let idx = activeExercises.firstIndex(where: { $0.id == exerciseID }) else { return }
        let lastWeight = activeExercises[idx].sets.last?.weight ?? 60.0
        let lastReps = activeExercises[idx].sets.last?.reps ?? 10
        activeExercises[idx].sets.append(WorkoutSet(weight: lastWeight, reps: lastReps))
        let impact = UIImpactFeedbackGenerator(style: .medium)
        impact.impactOccurred()
    }
    
    func toggleSet(exerciseID: UUID, setID: UUID) {
        guard let exIdx = activeExercises.firstIndex(where: { $0.id == exerciseID }),
              let setIdx = activeExercises[exIdx].sets.firstIndex(where: { $0.id == setID }) else { return }
        activeExercises[exIdx].sets[setIdx].isCompleted.toggle()
        
        let impact = UIImpactFeedbackGenerator(style: .rigid)
        impact.impactOccurred()
        
        if activeExercises[exIdx].sets[setIdx].isCompleted {
            startRestTimer(seconds: 90)
        }
    }
    
    func sendMessageToCoach(text: String) {
        guard !text.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        let userMsg = ChatMessage(sender: "user", text: text, time: "Сейчас")
        chatMessages.append(userMsg)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            let replyText = self.generateCoachAnswer(for: text)
            self.chatMessages.append(ChatMessage(sender: "coach", text: replyText, time: "Сейчас"))
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.success)
            self.saveData()
        }
        saveData()
    }
    
    private func generateCoachAnswer(for query: String) -> String {
        let q = query.lowercased()
        if q.contains("жим") {
            return "Жим лёжа: сведи лопатки, опусти плечи вниз к тазу. Локти держи под углом 70-75° к корпусу, гриф опускай на линию низа груди с паузой 1 сек. Выжимай мощно на выдохе."
        } else if q.contains("креатин") {
            return "Креатин моногидрат: принимай стабильно по 5 грамм каждый день в одно и то же время, запивая водой. Накопительный эффект наступит через 2-3 недели."
        } else if q.contains("размин") {
            return "Пирамида разминки: 1) Гриф × 15-20 раз; 2) 50% от рабочего × 8 раз; 3) 70% × 4 раза; 4) 85% × 1-2 раза. После 2 минут отдыха переходи к рабочим подходам!"
        } else {
            return "Держи прогрессию нагрузок: добавляй либо 1 повторение в подходе, либо 1-2.5 кг к штанге каждую неделю при чистой технике."
        }
    }
    
    private func defaultExercises(for title: String) -> [Exercise] {
        if title.contains("Спина") {
            return [
                Exercise(name: "Тяга верхнего блока к груди", muscleGroup: "Спина", sets: [
                    WorkoutSet(weight: 55, reps: 10),
                    WorkoutSet(weight: 60, reps: 10),
                    WorkoutSet(weight: 65, reps: 8)
                ]),
                Exercise(name: "Тяга горизонтального блока к поясу", muscleGroup: "Спина", sets: [
                    WorkoutSet(weight: 50, reps: 10),
                    WorkoutSet(weight: 55, reps: 10)
                ]),
                Exercise(name: "Махи гантелями в стороны", muscleGroup: "Плечи", sets: [
                    WorkoutSet(weight: 10, reps: 12),
                    WorkoutSet(weight: 12, reps: 12)
                ])
            ]
        } else if title.contains("Руки") {
            return [
                Exercise(name: "Французский жим с EZ-грифом", muscleGroup: "Трицепс", sets: [
                    WorkoutSet(weight: 30, reps: 10),
                    WorkoutSet(weight: 35, reps: 8)
                ]),
                Exercise(name: "Разгибания на блоке с канатом", muscleGroup: "Трицепс", sets: [
                    WorkoutSet(weight: 25, reps: 12),
                    WorkoutSet(weight: 30, reps: 10)
                ]),
                Exercise(name: "Сгибания на предплечья (хват)", muscleGroup: "Хват", sets: [
                    WorkoutSet(weight: 20, reps: 15),
                    WorkoutSet(weight: 25, reps: 12)
                ])
            ]
        } else {
            return [
                Exercise(name: "Жим штанги лёжа", muscleGroup: "Грудь", sets: [
                    WorkoutSet(weight: 70, reps: 8),
                    WorkoutSet(weight: 75, reps: 8),
                    WorkoutSet(weight: 80, reps: 6)
                ]),
                Exercise(name: "Жим гантелей на наклонной скамье", muscleGroup: "Грудь", sets: [
                    WorkoutSet(weight: 24, reps: 10),
                    WorkoutSet(weight: 26, reps: 8)
                ]),
                Exercise(name: "Подъем штанги на бицепс стоя", muscleGroup: "Бицепс", sets: [
                    WorkoutSet(weight: 35, reps: 10),
                    WorkoutSet(weight: 40, reps: 8)
                ])
            ]
        }
    }
    
    private func saveData() {
        if let encoded = try? JSONEncoder().encode(history) {
            UserDefaults.standard.set(encoded, forKey: "ironlog_history")
        }
        if let encoded = try? JSONEncoder().encode(records) {
            UserDefaults.standard.set(encoded, forKey: "ironlog_records")
        }
        if let encoded = try? JSONEncoder().encode(chatMessages) {
            UserDefaults.standard.set(encoded, forKey: "ironlog_chat")
        }
    }
    
    private func loadData() {
        if let data = UserDefaults.standard.data(forKey: "ironlog_history"),
           let decoded = try? JSONDecoder().decode([CompletedWorkout].self, from: data) {
            self.history = decoded
        }
        if let data = UserDefaults.standard.data(forKey: "ironlog_records"),
           let decoded = try? JSONDecoder().decode([PersonalRecord].self, from: data) {
            self.records = decoded
        } else {
            self.records = [
                PersonalRecord(exerciseName: "Жим штанги лёжа", weight: 90, date: Date()),
                PersonalRecord(exerciseName: "Жим гантелей 30°", weight: 32, date: Date()),
                PersonalRecord(exerciseName: "Бицепс со штангой", weight: 45, date: Date())
            ]
        }
        if let data = UserDefaults.standard.data(forKey: "ironlog_chat"),
           let decoded = try? JSONDecoder().decode([ChatMessage].self, from: data) {
            self.chatMessages = decoded
        }
    }
}

@main
struct IronLogApp: App {
    @StateObject private var store = WorkoutStore()
    
    var body: some Scene {
        WindowGroup {
            MainTabView()
                .environmentObject(store)
                .preferredColorScheme(.dark)
        }
    }
}
