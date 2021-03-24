//
//  ContentView.swift
//  SampleSwiftUI
//
//  Created by 開発 on 3/24/21.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        MyMtkView()
            .ignoresSafeArea()
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
