//
//  ContentView.swift
//  Calu by fc
//
//  Created by 大塚航希 on 2025/06/19.
//

import SwiftUI
import PhotosUI

struct ContentView: View {
    @State private var selectedTab = 0
    @State private var showingCamera = false
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var capturedImage: UIImage?
    
    var body: some View {
        TabView(selection: $selectedTab) {
            HomeView(showingCamera: $showingCamera, capturedImage: $capturedImage)
                .tabItem {
                    Label("Today", systemImage: "sun.max.fill")
                }
                .tag(0)
            
            HistoryView()
                .tabItem {
                    Label("History", systemImage: "clock.fill")
                }
                .tag(1)
            
            ProfileView()
                .tabItem {
                    Label("Profile", systemImage: "person.fill")
                }
                .tag(2)
        }
        .tint(.primary)
        .background(Color.white)
        .sheet(isPresented: $showingCamera) {
            CameraView(capturedImage: $capturedImage)
        }
    }
}

#Preview {
    ContentView()
}
