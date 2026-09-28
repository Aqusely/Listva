//
//  ContentView.swift
//  Listva
//
//  Created by Наливайко Кирилл on 27.09.2026.
//

import SwiftUI
internal import Combine


// Структура растения
struct Plant: Identifiable, Codable {
    var id = UUID()
    let name: String
    let type: String
    let room: String
    let interval: Int
    var lastWatered: Date
    let note: String
    
    var daysLeft: Int {
        let calendar = Calendar.current
        let start = calendar.startOfDay(for: lastWatered)
        let today = calendar.startOfDay(for: Date())
        let passed = calendar.dateComponents([.day], from: start, to: today).day ?? 0
        return interval - passed
    }
}

extension Plant{
    
    var iconName: String{
        switch type{
        case "Цветущее":
            return "camera.macro"
        case "Суккулент", "Кактус":
            return "tree"
        default:
            return "leaf.fill"
        }
    }
    
    // Цвет иконки
    var iconColor: Color{
        switch type{
        case "Цветущее":
            return .bloom
        case "Суккулент", "Кактус":
            return .desert
        default:
            return .forest
        }
    }
    
    //Цвет кружка
    var circleColor: Color{
        switch type{
        case "Цветущее":
            return .bloomSoft
        case "Суккулент", "Кактус":
            return .desrtSoft
        default:
            return .leafSoft
        }
    }
    
    // Дата следующего полива 
    var nextDayWater: Date {
        Calendar.current.date(byAdding: .day, value: interval, to: lastWatered) ?? lastWatered
    }
    
    var daysPased: Int {
        interval - daysLeft
    }
}

struct PillStyle: ViewModifier {
    
    let textColor: Color
    let backgroundColor: Color
    
    func body(content: Content) -> some View {
        content
            .font(.caption.weight(.semibold))
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .foregroundStyle(textColor)
            .background(backgroundColor)
            .clipShape(Capsule())
    }
}

struct PrimaryButton: ViewModifier{
    
    let backgroundColor: Color
    
    func body(content: Content) -> some View {
        content
            .font(.headline)
            .foregroundStyle(.white)
            .padding(.horizontal, 24)
            .frame(height: 52)
            .background(backgroundColor)
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .padding(.top, 16)
    }
}

extension View{
    func pillStyle(text: Color, background: Color) -> some View {
        self.modifier(PillStyle(textColor: text, backgroundColor: background))
    }
    
    func primaryButton(backgroundColor: Color) -> some View {
        self.modifier(PrimaryButton(backgroundColor: backgroundColor))
    }
}

struct SummaryCard: View{
    var count: Int
    var total: Int
    
    var body: some View{
        HStack{
            VStack(alignment: .leading, spacing: 2){
                Text("Сегодня полить")
                    .font(.subheadline)
                    .opacity(0.85)
                Text("\(count) растения")
                    .font(.system(size: 34, weight: .bold, design: .rounded))
                Text("Всего в коллекции: \(total)")
                    .font(.footnote)
                    .opacity(0.75)
            }
            Spacer()
            Image(systemName: "drop.fill")
                .font(.system(size: 28))
                .frame(width: 60, height: 60)
                .background(.white.opacity(0.16))
                .clipShape(Circle())
        }
        .foregroundStyle(.white)
        .padding(20)
        .background(.forest)
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }
}

// Структура пустого экрана
struct EmptyGardenView: View {
    
    @Binding var addPlant: Bool
    
    var body: some View {
        VStack{
            Spacer()
            VStack(spacing: 12){
                Image(systemName: "leaf.fill")
                    .font(.system(size: 56))
                    .foregroundStyle(.forest)
                    .frame(width: 128, height: 128)
                    .background(.leafSoft)
                    .clipShape(Circle())
                Text("Здесь пока пусто")
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                Text("Добавьте первое растение — и Листва напомнит, когда его полить.")
                    .foregroundColor(.stone)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
                Button {
                    addPlant = true
                } label: {
                    Label("Добавить растение", systemImage: "plus")
                        .primaryButton(backgroundColor: .forest)
                }
            }
            Spacer()
        }.frame(maxWidth: .infinity)
    }
}

// Структура опрееляет строки в List
struct PlantRow: View{
    @Binding var plant: Plant
    
    var body: some View {
        
        HStack(spacing: 12){
            Image(systemName: plant.iconName)
                .font(.system(size: 20))
                .foregroundStyle(plant.iconColor)
                .frame(width: 44, height: 44)
                .background(plant.circleColor)
                .clipShape(Circle())
            VStack(alignment: .leading, spacing: 2){
                Text(plant.name)
                    .font(.headline)
                Text("\(plant.room) · раз в \(plant.interval) дн.")
                    .font(.subheadline)
                    .foregroundStyle(Color("Stone"))
                
            }
            Spacer()
            if plant.daysLeft <= 0 {
                Button(action: {
                    withAnimation{
                        plant.lastWatered = Date()
                    }
                }){
                    Image(systemName: "drop.fill")
                        .font(.system(size: 18))
                        .foregroundStyle(.water)
                        .frame(width: 44, height: 44)
                        .background(.waterSoft)
                        .clipShape(Circle())
                }.buttonStyle(.borderless)
            }else {
                Text("Через \(plant.daysLeft) дн.")
                    .pillStyle(text: .forest, background: .leafSoft)
            }
            
        }
    }
    
    
}

class Garden: ObservableObject{
    @Published var plants = [Plant]() {
        didSet{
            let encoder = JSONEncoder()
            if let encoded = try? encoder.encode(plants) {
                UserDefaults.standard.set(encoded, forKey: "plants")
            }
        }
    }
    
    init(){
        if let data = UserDefaults.standard.data(forKey: "plants") {
            if let decoded = try? JSONDecoder().decode([Plant].self, from: data) {
                plants = decoded
            }
        }
    }
}


struct ContentView: View {
    
    
    @StateObject var garden = Garden()
    
    @State private var addPlant: Bool = false //Добавляю растение
    @State private var showDeleteAlert = false // Уведомление для удаления
    @State private var plantToDelete: Plant.ID? // id растения, которое хотим удалить
    
    // Для секции сейчас
    var needWater: [Binding<Plant>] {
        $garden.plants.filter{ $0.wrappedValue.daysLeft <= 0 }
    }
    
    // Секция позже
    var later: [Binding<Plant>] {
        $garden.plants.filter{ $0.wrappedValue.daysLeft > 0 }
    }
    
    private var plantNameToDelete: String{
        guard let name = garden.plants.first(where: {$0.id == plantToDelete})?.name else { return "растение" }
        return name
    }
    
    var body: some View {
        NavigationView{
            Group{
                if garden.plants.isEmpty{
                    EmptyGardenView(addPlant: $addPlant)
                }else{
                    List{
                        SummaryCard(count: needWater.count, total: garden.plants.count)
                            .listRowBackground(Color.clear)
                            .listRowInsets(EdgeInsets())
                        if !needWater.isEmpty{
                            Section("Нужно полить"){
                                ForEach(needWater, id: \.wrappedValue.id){ plant in
                                    ZStack{
                                        NavigationLink(destination: PlantDetailView(garden: garden, plant: plant)){
                                                EmptyView()
                                        }
                                        .opacity(0)
                                        PlantRow(plant: plant)
                                    }
                                }.onDelete{ offsets in
                                    askToDelete(from: needWater, at: offsets)
                                }
                            }
                        }
                        
                        if !later.isEmpty{
                            Section("Позже"){
                                ForEach(later, id: \.wrappedValue.id){ plant in
                                    ZStack{
                                        NavigationLink(destination: PlantDetailView(garden: garden,plant: plant)){
                                            EmptyView()
                                        }
                                        .opacity(0)
                                        PlantRow(plant: plant)
                                    }
                                }.onDelete{ offsets in
                                    askToDelete(from: later, at: offsets)
                                }
                            }
                        }
                    }
                }
            }
            .navigationBarTitle(Text("Мои растения"))
            .navigationBarItems(trailing:
                Button(action: {
                    self.addPlant = true
                }){
                    Image(systemName: "plus")
                })
            .sheet(isPresented: $addPlant) {
                AddPlant(garden: self.garden)
            }
            .scrollContentBackground(.hidden)
            .background(Color("Paper"))
            .alert("Удалить «\(plantNameToDelete)»?", isPresented: $showDeleteAlert, presenting: plantToDelete){ id in
                Button("Удалить", role: .destructive){
                    garden.plants.removeAll { $0.id == id }
                }
                Button("Отмена", role: .cancel){}
            } message: { _ in
                Text("Растение и вся история полива исчезнут.")
            }
        }
    }
    
    // Запоминаем, какое растение удалить, и показываем alert
    func askToDelete(from section: [Binding<Plant>], at offsets: IndexSet) {
        if let index = offsets.first {
            plantToDelete = section[index].wrappedValue.id
            showDeleteAlert = true
        }
    }
}


#Preview {
    ContentView()
}
