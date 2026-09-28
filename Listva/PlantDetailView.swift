//
//  PlantDetailView.swift
//  Listva
//
//  Created by Наливайко Кирилл on 28.09.2026.
//

import SwiftUI

struct StatTile: View{
    var title: String
    var value: String
    
    var body: some View{
        VStack(alignment: .leading){
            Text(title)
                .font(.caption.weight(.semibold))
                    .foregroundStyle(.stone)
            Text(value)
                .font(.system(.title3, design: .rounded, weight: .semibold))
        }.frame(maxWidth: .infinity, alignment: .leading)
            .padding(14)
            .background(.white)
            .clipShape(RoundedRectangle(cornerRadius: 16))
        
    }
}

struct PlantDetailView: View {
    
    @Environment(\.dismiss) var dismiss
    
    @ObservedObject var garden: Garden
    @Binding var plant: Plant
    @State private var showAlert = false
    
    var body: some View {
        ScrollView{
            VStack(spacing: 8){
                VStack(alignment: .center, spacing: 12){
                    Image(systemName: plant.iconName)
                        .font(.system(size: 50))
                        .foregroundStyle(plant.iconColor)
                        .frame(width: 104, height: 104)
                        .background(plant.circleColor)
                        .clipShape(Circle())
                        .padding(.bottom, 8)
                    Text("\(plant.name)")
                        .font(.system(.title, design: .rounded, weight: .bold))
                    Text("\(plant.type) · \(plant.room)")
                        .font(.subheadline)
                        .foregroundStyle(.stone)
                    if plant.daysLeft <= 0 {
                        Text("Полить сегодня").pillStyle(text: .clay, background: .claySoft)
                    }else {
                        Text("Полить через \(plant.daysLeft) дн.").pillStyle(text: .forest, background: .leafSoft)
                    }
                }.padding(.bottom, 12)
                HStack{
                    StatTile(title: "Интервал", value: "\(plant.interval) дн.")
                    StatTile(title: "Последний", value: plant.lastWatered.formatted(.dateTime.day().month()))
                    StatTile(title: "Следующий", value: plant.nextDayWater.formatted(.dateTime.day().month()))
                }
                VStack(spacing: 10){
                    HStack{
                        Text("С последнего полива")
                            .font(.subheadline)
                            .foregroundStyle(.stone)
                        Spacer()
                        Text("\(min(plant.daysPased, plant.interval)) из \(plant.interval)")
                            .font(.subheadline.weight(.semibold))
                    }
                    ProgressView(value: Double(min(plant.daysPased, plant.interval)),total: Double(plant.interval))
                        .tint(plant.daysLeft <= 0 ? .clay : .forest)
                }
                    .padding(14)
                    .background(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                
                if !plant.note.isEmpty {
                    VStack(alignment: .leading){
                        Text("ЗАМЕТКА")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.stone)
                            .tracking(0.3)
                        Text("\(plant.note)")
                            .font(.body)
                            .lineSpacing(3)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(14)
                    .background(Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                }
                
                VStack(spacing: 12){
                    Button(action: {
                        plant.lastWatered = Date()
                    }){
                        Label("Полить сейчас", systemImage: "drop.fill")
                            .frame(maxWidth: .infinity)
                            .primaryButton(backgroundColor: .water)
                        
                    }
                    Button("Удалить растение", role: .destructive){
                        self.showAlert = true
                    }
                }
            }.frame(maxWidth: .infinity)
                .padding(.horizontal, 16)
        }.background(.paper)
            .alert(isPresented: $showAlert){
                Alert(title: Text("\(plant.name)"), message: Text("Вы уверены что хотите удалить \(plant.name)?"), primaryButton: .cancel(), secondaryButton: .destructive(Text("Удалить")){
                        let id = plant.id
                        dismiss()
                        garden.plants.removeAll { $0.id == id }
                })
            }
    }
}

#Preview {
    PlantDetailView(garden: Garden(), plant: .constant(
        Plant(name: "Монстера",
              type: "Тропическое",
              room: "Гостиная",
              interval: 7,
              lastWatered: Date(),
              note: "Не любит прямое солнце")
    ))
}
