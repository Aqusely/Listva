//
//  AddPlant.swift
//  Listva
//
//  Created by Наливайко Кирилл on 28.09.2026.
//

import SwiftUI

struct AddPlant: View{
    
    @Environment(\.dismiss) var dismiss
    
    @ObservedObject var garden: Garden
    
    @State private var plantName: String = ""
    @State private var type: String = "Тропическое"
    @State private var place: String = "Гостиная"
    @State private var interval: Int = 7
    @State private var lastWatered = Date()
    @State private var plantNote: String = ""
    
    let types: [String] = ["Тропическое", "Цветущее", "Суккулент", "Кактус"]
    let placeList: [String] = ["Гостиная", "Спальня", "Кухня"]
    
    var body: some View{
        NavigationView{
            Form{
                Section("РАСТЕНИЕ"){
                    TextField("Название растения", text: $plantName)
                    Picker("Вид", selection: $type){
                        ForEach(types, id: \.self){
                            Text($0)
                        }
                    }
                }
                Section("ГДЕ СТОИТ"){
                    Picker("Комната", selection: $place){
                        ForEach(placeList, id: \.self){
                            Text($0)
                        }
                    }.pickerStyle(.segmented)
                        .listRowBackground(Color.clear)
                        .listRowInsets(EdgeInsets())
                }
                Section(header: Text("ПОЛИВ"), footer: Text("Когда подойдет срок, растение появится в разделе «Нужно полить»")){
                    Stepper("Каждые \(interval) дн.", value: $interval, in: 1...30)
                    DatePicker("Последний полив",selection: $lastWatered, in: ...Date(), displayedComponents: .date)
                }
                Section("ЗАМЕТКИ"){
                    TextField("Например: не любит прямое солнце", text: $plantNote)
                }
            }
            .scrollContentBackground(.hidden)
            .background(.paper)
            .navigationBarTitle(Text("Добавить"), displayMode: .inline)
                .toolbar{
                    ToolbarItem(placement: .cancellationAction){
                        Button("Отмена"){
                            dismiss()
                        }
                    }
                    .sharedBackgroundVisibility(.hidden)
                    
                    ToolbarItem(placement: .confirmationAction){
                        Button("Сохранить"){
                            let plant = Plant(name: plantName,
                                              type: type,
                                              room: place,
                                              interval: self.interval,
                                              lastWatered: self.lastWatered,
                                              note: plantNote)
                            self.garden.plants.append(plant)
                            dismiss()
                        }.disabled(plantName .isEmpty)
                    }
                    .sharedBackgroundVisibility(.hidden)
                }
        }
    }
}

#Preview {
    AddPlant(garden: Garden())
}
