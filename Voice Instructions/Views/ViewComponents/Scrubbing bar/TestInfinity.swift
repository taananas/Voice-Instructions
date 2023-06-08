//
//  TestInfinity.swift
//  Voice Instructions
//
//

import SwiftUI

class Item {
    var value: Int
    // Other properties
    
    init(value: Int) {
        self.value = value
    }
}

struct ItemWrapped: Identifiable {
    let id = UUID()
    
    var wrapped: Item
}

struct TestInfinity: View {
    static let itemRaw = (0..<10).map { Item(value: $0) }
    
    @State private var items = [ItemWrapped(wrapped: itemRaw.first!)]
    @State private var index = 0
    
    var body: some View {
        VStack {
            Text("\(index)")
            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(spacing: 10) {
                    ForEach(items) { item in
                        ZStack{
                            Circle()
                            Text(item.wrapped.value.formatted())
                                .foregroundColor(.white)
                        }
                        .onAppear {
                            // Index iteration
                            index = (index + 1) % TestInfinity.itemRaw.count
                            
                            items.append(
                                ItemWrapped(wrapped: TestInfinity.itemRaw[index]))
                        }
                        .onAppear {
                            // Index iteration
                            if items[1].id == item.id{
                                items.insert(item, at: 0)
                            }
                        }
                    }
                }.padding()
            }.frame(height: 100)
        }
    }
}

struct TestInfinity_Previews: PreviewProvider {
    static var previews: some View {
        ZStack{
            //Color.black
            TestInfinity()
        }
    }
}
