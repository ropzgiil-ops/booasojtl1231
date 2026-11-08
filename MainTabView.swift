import SwiftUI

struct MainTabView: View {
    @EnvironmentObject var store: WorkoutStore
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            WorkoutView()
                .tabItem {
                    Label("Зал", systemImage: "bolt.fill")
                }
                .tag(0)
            
            RecordsView()
                .tabItem {
                    Label("Прогресс", systemImage: "trophy.fill")
                }
                .tag(1)
            
            TimerView()
                .tabItem {
                    Label("Таймер", systemImage: "stopwatch.fill")
                }
                .tag(2)
            
            HistoryView()
                .tabItem {
                    Label("История", systemImage: "calendar")
                }
                .tag(3)
            
            CoachChatView()
                .tabItem {
                    Label("Тренер AI", systemImage: "bubble.left.and.bubble.right.fill")
                }
                .tag(4)
        }
        .accentColor(Color.cyan)
    }
}

struct WorkoutView: View {
    @EnvironmentObject var store: WorkoutStore
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(red: 0.03, green: 0.05, blue: 0.08).ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 16) {
                        if store.isWorkoutActive {
                            activeWorkoutHeader
                            
                            ForEach(store.activeExercises) { exercise in
                                ExerciseCard(exercise: exercise)
                            }
                            
                            Button(action: { store.finishWorkout() }) {
                                HStack {
                                    Image(systemName: "checkmark.circle.fill")
                                    Text("Завершить тренировку")
                                }
                                .font(.headline)
                                .foregroundColor(.black)
                                .frame(maxWidth: .infinity)
                                .frame(height: 52)
                                .background(LinearGradient(colors: [.cyan, .teal], startPoint: .leading, endPoint: .trailing))
                                .cornerRadius(14)
                                .shadow(color: .cyan.opacity(0.4), radius: 8, y: 4)
                            }
                            .padding(.top, 10)
                        } else {
                            idleWorkoutHeader
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("IronLog DDX")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
    
    var idleWorkoutHeader: some View {
        VStack(spacing: 20) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Твой 3-дневный сплит (Верх тела)")
                    .font(.caption)
                    .foregroundColor(.cyan)
                    .fontWeight(.bold)
                Text("Время качать железо!")
                    .font(.title2)
                    .fontWeight(.heavy)
                    .foregroundColor(.white)
                Text("Сплит: 1. Грудь/Бицепс  •  2. Спина/Плечи  •  3. Трицепс/Хват")
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
            .background(Color(red: 0.07, green: 0.1, blue: 0.15))
            .cornerRadius(16)
            
            VStack(spacing: 12) {
                splitButton(title: "⚡ День 1: Грудь & Бицепс", subtitle: "Жим штанги, наклонные гантели, бицепс стоя") {
                    store.startWorkout(title: "День 1: Грудь & Бицепс")
                }
                splitButton(title: "⚡ День 2: Спина & Плечи", subtitle: "Верхний блок, тяга к поясу, махи") {
                    store.startWorkout(title: "День 2: Спина & Плечи")
                }
                splitButton(title: "⚡ День 3: Трицепс & Хват", subtitle: "Французский жим, канат, предплечья") {
                    store.startWorkout(title: "День 3: Трицепс & Хват")
                }
            }
        }
    }
    
    var activeWorkoutHeader: some View {
        HStack {
            VStack(alignment: .leading) {
                Text("ИДЕТ ТРЕНИРОВКА")
                    .font(.caption2)
                    .foregroundColor(.cyan)
                    .fontWeight(.bold)
                Text(formatTime(store.workoutTimerSeconds))
                    .font(.title)
                    .fontWeight(.heavy)
                    .foregroundColor(.white)
            }
            Spacer()
            if store.isRestTimerRunning {
                VStack(alignment: .trailing) {
                    Text("ОТДЫХ")
                        .font(.caption2)
                        .foregroundColor(.orange)
                        .fontWeight(.bold)
                    Text("\(store.restTimerSeconds) сек")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.orange)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.orange.opacity(0.15))
                .cornerRadius(10)
            }
        }
        .padding()
        .background(Color(red: 0.07, green: 0.1, blue: 0.15))
        .cornerRadius(14)
    }
    
    func splitButton(title: String, subtitle: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .foregroundColor(.white)
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
            .background(Color(red: 0.08, green: 0.12, blue: 0.18))
            .cornerRadius(14)
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(Color.cyan.opacity(0.3), lineWidth: 1)
            )
        }
    }
    
    func formatTime(_ totalSeconds: Int) -> String {
        let m = totalSeconds / 60
        let s = totalSeconds % 60
        return String(format: "%02d:%02d", m, s)
    }
}

struct ExerciseCard: View {
    @EnvironmentObject var store: WorkoutStore
    var exercise: Exercise
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(exercise.name)
                    .font(.headline)
                    .foregroundColor(.white)
                Spacer()
                Text(exercise.muscleGroup)
                    .font(.caption2)
                    .fontWeight(.bold)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.cyan.opacity(0.2))
                    .foregroundColor(.cyan)
                    .cornerRadius(6)
            }
            
            VStack(spacing: 8) {
                ForEach(Array(exercise.sets.enumerated()), id: \.element.id) { index, set in
                    HStack {
                        Text("\(index + 1)")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                            .frame(width: 24)
                        
                        Text("\(Int(set.weight)) кг × \(set.reps)")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.white)
                        
                        if set.oneRepMax > 0 {
                            Text("1RM: \(Int(set.oneRepMax)) кг")
                                .font(.caption2)
                                .foregroundColor(.cyan)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.cyan.opacity(0.1))
                                .cornerRadius(4)
                        }
                        
                        Spacer()
                        
                        Button(action: {
                            store.toggleSet(exerciseID: exercise.id, setID: set.id)
                        }) {
                            Image(systemName: set.isCompleted ? "checkmark.circle.fill" : "circle")
                                .font(.title3)
                                .foregroundColor(set.isCompleted ? .teal : .gray)
                        }
                    }
                    .padding(.vertical, 6)
                    .padding(.horizontal, 10)
                    .background(set.isCompleted ? Color.teal.opacity(0.1) : Color(red: 0.05, green: 0.08, blue: 0.12))
                    .cornerRadius(8)
                }
            }
            
            Button(action: { store.addSet(to: exercise.id) }) {
                HStack {
                    Image(systemName: "plus")
                    Text("Добавить подход")
                }
                .font(.caption)
                .fontWeight(.bold)
                .foregroundColor(.cyan)
                .frame(maxWidth: .infinity)
                .frame(height: 34)
                .background(Color.cyan.opacity(0.12))
                .cornerRadius(8)
            }
        }
        .padding()
        .background(Color(red: 0.07, green: 0.1, blue: 0.15))
        .cornerRadius(14)
    }
}

struct RecordsView: View {
    @EnvironmentObject var store: WorkoutStore
    @State private var newExerciseName = ""
    @State private var newWeight = ""
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(red: 0.03, green: 0.05, blue: 0.08).ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 20) {
                        VStack(spacing: 12) {
                            Text("Твои рекорды (1RM)")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            
                            ForEach(store.records) { rec in
                                HStack {
                                    VStack(alignment: .leading) {
                                        Text(rec.exerciseName)
                                            .font(.headline)
                                            .foregroundColor(.white)
                                        Text(rec.date, style: .date)
                                            .font(.caption2)
                                            .foregroundColor(.gray)
                                    }
                                    Spacer()
                                    Text("\(Int(rec.weight)) кг")
                                        .font(.title3)
                                        .fontWeight(.heavy)
                                        .foregroundColor(.cyan)
                                }
                                .padding()
                                .background(Color(red: 0.07, green: 0.1, blue: 0.15))
                                .cornerRadius(12)
                            }
                        }
                        
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Записать новый рекорд")
                                .font(.headline)
                                .foregroundColor(.white)
                            
                            TextField("Упражнение", text: $newExerciseName)
                                .padding()
                                .background(Color(red: 0.07, green: 0.1, blue: 0.15))
                                .cornerRadius(10)
                                .foregroundColor(.white)
                            
                            TextField("Максимальный вес (кг)", text: $newWeight)
                                .keyboardType(.decimalPad)
                                .padding()
                                .background(Color(red: 0.07, green: 0.1, blue: 0.15))
                                .cornerRadius(10)
                                .foregroundColor(.white)
                            
                            Button(action: saveRecord) {
                                Text("Сохранить рекорд")
                                    .fontWeight(.bold)
                                    .foregroundColor(.black)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 48)
                                    .background(Color.cyan)
                                    .cornerRadius(10)
                            }
                        }
                        .padding()
                        .background(Color(red: 0.05, green: 0.08, blue: 0.12))
                        .cornerRadius(14)
                    }
                    .padding()
                }
            }
            .navigationTitle("Прогресс")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
    
    func saveRecord() {
        guard let w = Double(newWeight), !newExerciseName.isEmpty else { return }
        store.records.append(PersonalRecord(exerciseName: newExerciseName, weight: w, date: Date()))
        newExerciseName = ""
        newWeight = ""
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
    }
}

struct TimerView: View {
    @EnvironmentObject var store: WorkoutStore
    @State private var selectedSeconds = 90
    
    var body: some View {
        ZStack {
            Color(red: 0.03, green: 0.05, blue: 0.08).ignoresSafeArea()
            
            VStack(spacing: 30) {
                Text("Таймер отдыха")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                ZStack {
                    Circle()
                        .stroke(Color.gray.opacity(0.2), lineWidth: 16)
                        .frame(width: 240, height: 240)
                    Circle()
                        .stroke(Color.cyan, style: StrokeStyle(lineWidth: 16, lineCap: .round))
                        .frame(width: 240, height: 240)
                    
                    VStack {
                        Text("\(store.restTimerSeconds)")
                            .font(.system(size: 64, weight: .heavy, design: .rounded))
                            .foregroundColor(.white)
                        Text("СЕКУНД")
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundColor(.gray)
                    }
                }
                
                HStack(spacing: 12) {
                    timerPresetButton(title: "60с", sec: 60)
                    timerPresetButton(title: "90с", sec: 90)
                    timerPresetButton(title: "120с", sec: 120)
                    timerPresetButton(title: "180с", sec: 180)
                }
                
                Button(action: {
                    if store.isRestTimerRunning {
                        store.isRestTimerRunning = false
                    } else {
                        store.startRestTimer(seconds: selectedSeconds)
                    }
                }) {
                    Text(store.isRestTimerRunning ? "Остановить" : "Запустить таймер")
                        .font(.headline)
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity)
                        .frame(height: 52)
                        .background(store.isRestTimerRunning ? Color.orange : Color.cyan)
                        .cornerRadius(14)
                }
                .padding(.horizontal, 40)
            }
            .padding()
        }
    }
    
    func timerPresetButton(title: String, sec: Int) -> some View {
        Button(action: {
            selectedSeconds = sec
            store.startRestTimer(seconds: sec)
        }) {
            Text(title)
                .font(.headline)
                .foregroundColor(.white)
                .frame(width: 68, height: 44)
                .background(Color(red: 0.08, green: 0.12, blue: 0.18))
                .cornerRadius(10)
        }
    }
}

struct HistoryView: View {
    @EnvironmentObject var store: WorkoutStore
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(red: 0.03, green: 0.05, blue: 0.08).ignoresSafeArea()
                
                if store.history.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "calendar.badge.clock")
                            .font(.system(size: 48))
                            .foregroundColor(.gray)
                        Text("История пока пуста")
                            .font(.headline)
                            .foregroundColor(.gray)
                    }
                } else {
                    List {
                        ForEach(store.history) { item in
                            VStack(alignment: .leading, spacing: 6) {
                                Text(item.title)
                                    .font(.headline)
                                    .foregroundColor(.white)
                                HStack {
                                    Text(item.date, style: .date)
                                    Spacer()
                                    Text("Тоннаж: \(Int(item.totalVolume)) кг")
                                        .foregroundColor(.cyan)
                                    Text("• Подходов: \(item.totalSets)")
                                }
                                .font(.caption)
                                .foregroundColor(.gray)
                            }
                            .padding(.vertical, 4)
                            .listRowBackground(Color(red: 0.07, green: 0.1, blue: 0.15))
                        }
                    }
                    .scrollContentBackground(.hidden)
                }
            }
            .navigationTitle("История тренировок")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

struct CoachChatView: View {
    @EnvironmentObject var store: WorkoutStore
    @State private var inputText = ""
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(red: 0.03, green: 0.05, blue: 0.08).ignoresSafeArea()
                
                VStack {
                    ScrollViewReader { proxy in
                        ScrollView {
                            LazyVStack(spacing: 12) {
                                ForEach(store.chatMessages) { msg in
                                    HStack {
                                        if msg.sender == "user" { Spacer() }
                                        Text(msg.text)
                                            .padding()
                                            .background(msg.sender == "user" ? Color.cyan.opacity(0.25) : Color(red: 0.08, green: 0.12, blue: 0.18))
                                            .foregroundColor(.white)
                                            .cornerRadius(14)
                                            .frame(maxWidth: 280, alignment: msg.sender == "user" ? .trailing : .leading)
                                        if msg.sender == "coach" { Spacer() }
                                    }
                                    .id(msg.id)
                                }
                            }
                            .padding()
                        }
                        .onChange(of: store.chatMessages.count) { _ in
                            if let last = store.chatMessages.last {
                                proxy.scrollTo(last.id, anchor: .bottom)
                            }
                        }
                    }
                    
                    HStack {
                        TextField("Спроси тренера о технике...", text: $inputText)
                            .padding(12)
                            .background(Color(red: 0.08, green: 0.12, blue: 0.18))
                            .cornerRadius(10)
                            .foregroundColor(.white)
                        
                        Button(action: send) {
                            Image(systemName: "paperplane.fill")
                                .font(.title3)
                                .foregroundColor(.cyan)
                                .padding(10)
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("IronCoach AI")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
    
    func send() {
        let text = inputText
        inputText = ""
        store.sendMessageToCoach(text: text)
    }
}
