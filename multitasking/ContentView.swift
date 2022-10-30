//
//  ContentView.swift
//  multitasking
//
//  Created by HingTatTsang on 26/10/2022.
//

import SwiftUI
import WebKit
import WebView
import Combine

struct settingsView: View {
    @State var pageurl = "http://google.com"
    var body: some View {
        NavigationView {
            List {
                HStack {
                    Text("預設首頁：")
                    TextEditor(text: $pageurl)
                }
            }
            .onAppear() {
                pageurl = getdata().getdefaultsdata(type: "urldef")
            }
            .onDisappear() {
                getdata().savedefaultsdata(type: "urldef", data: pageurl)
            }
                
                
                .navigationTitle("設定")
                
            }
            .navigationViewStyle(StackNavigationViewStyle())
    }
}

struct mainappView: View {
    var body: some View {
        TabView {
            Group {
                mainView()
                    .tabItem {
                        Label("主頁", systemImage: "house")
                    }
                    .tag(1)
                settingsView()
                    .tabItem {
                        Label("設定", systemImage: "command.circle")
                    }
                    .tag(2)
            }
        }
    }
}

struct mainView: View {
    @State var number = [""]
    var body: some View {
        
        ZStack {
            Image("own")
                .resizable()
            VStack {
                HStack {
                    Button("add") {
                        number.append("")
                    }
                }
                ForEach((1...number.count), id: \.self) {i in
                    ZStack {
                        main2View()
                    }
                }
            }
        }
        
    }
}

struct main2View: View {
    @State var hidden = false
    var body: some View {
        Group {
            if hidden == true {
                
            } else {
                DraggableCircles()
                    .onTapGesture(count: 2) {
                        hidden = true
                    }
            }
            
        }
    }
}

struct AppContentView: View {
    @ObservedObject var externalDisplayContent = ExternalDisplayContent()
    @State var additionalWindows: [UIWindow] = []

    private var screenDidConnectPublisher: AnyPublisher<UIScreen, Never> {
        NotificationCenter.default
            .publisher(for: UIScreen.didConnectNotification)
            .compactMap { $0.object as? UIScreen }
            .receive(on: RunLoop.main)
            .eraseToAnyPublisher()
    }

    private var screenDidDisconnectPublisher: AnyPublisher<UIScreen, Never> {
        NotificationCenter.default
            .publisher(for: UIScreen.didDisconnectNotification)
            .compactMap { $0.object as? UIScreen }
            .receive(on: RunLoop.main)
            .eraseToAnyPublisher()
    }
    var body: some View {
        ContentView()
            .environmentObject(externalDisplayContent)
            .onReceive(
                screenDidConnectPublisher,
                perform: screenDidConnect
            )
            .onReceive(
                screenDidDisconnectPublisher,
                perform: screenDidDisconnect
            )
    }

    private func screenDidConnect(_ screen: UIScreen) {
        let window = UIWindow(frame: screen.bounds)

        window.windowScene = UIApplication.shared.connectedScenes
            .first { ($0 as? UIWindowScene)?.screen == screen }
            as? UIWindowScene

        let view = ExternalView()
            .environmentObject(externalDisplayContent)
        let controller = UIHostingController(rootView: view)
        window.rootViewController = controller
        window.isHidden = false
        additionalWindows.append(window)
        externalDisplayContent.isShowingOnExternalDisplay = true
    }

    private func screenDidDisconnect(_ screen: UIScreen) {
        additionalWindows.removeAll { $0.screen == screen }
        externalDisplayContent.isShowingOnExternalDisplay = false
    }


}


struct ContentView: View {
    @EnvironmentObject var externalDisplayContent: ExternalDisplayContent

    var body: some View {
        HStack {
            windowsView(refresh: $externalDisplayContent.refresh)
                
        }
    }

}


struct windowsView: View {
    @StateObject var webViewStore = WebViewStore()
    @EnvironmentObject var externalDisplayContent: ExternalDisplayContent
    @Binding var refresh: Bool
    var body: some View {
        VStack {
            HStack {
                ZStack {
                    HStack {
                        TextField("URL", text: $externalDisplayContent.url)
                            .padding(.horizontal)
                            .frame(height: 30)
                        Button("go") {
                            refresh = true
                            self.webViewStore.webView.load(URLRequest(url: URL(string: "\(externalDisplayContent.url)")!))
                        }
                        .padding(.horizontal)
                            .frame(height: 35)
                    }
                }
            }.frame(height: 35)
            Rectangle()
                .overlay() {
                    if refresh == false {
                        WebView(webView: webViewStore.webView)
                          .onAppear {
                              if getdata().getdefaultsdata(type: "urldef") != "" {
                                  self.webViewStore.webView.load(URLRequest(url: URL(string: "\(getdata().getdefaultsdata(type: "urldef"))")!))
                              } else {
                                  self.webViewStore.webView.load(URLRequest(url: URL(string: "\(externalDisplayContent.url)")!))
                              }
                           
                          }
                    } else {
                        refreshhelper(refresh: $refresh)
                    }
                    
                }
            HStack {
                ZStack {
                    HStack {
                        Spacer()
                        Button(action: goBack) {
                          Image(systemName: "chevron.left")
                            .imageScale(.large)
                            .aspectRatio(contentMode: .fit)
                        }.disabled(!webViewStore.canGoBack)
                            .padding()
                        Spacer()
                        Button(action: goForward) {
                          Image(systemName: "chevron.right")
                            .imageScale(.large)
                            .aspectRatio(contentMode: .fit)
                        }.disabled(!webViewStore.canGoForward)
                            .padding()
                        Spacer()
                    }
                }
              }.frame(height: 30)
        }
    }
    func goBack() {
      webViewStore.webView.goBack()
    }
    
    func goForward() {
      webViewStore.webView.goForward()
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }

}


class ExternalDisplayContent: ObservableObject {
    @Published var string = ""
    @Published var isShowingOnExternalDisplay = false
    @Published var url = "http://google.com"
    @Published var refresh = false
    
    

}


struct ExternalView: View {
    @EnvironmentObject var externalDisplayContent: ExternalDisplayContent

    var body: some View {
        ContentView()
    }

}

struct ExternalView_Previews: PreviewProvider {
    static var previews: some View {
        ExternalView()
    }

}

struct refreshhelper: View {
    @Binding var refresh: Bool
    var body: some View {
        Text("refresh !")
            .onAppear() {
                refresh = false
            }
    }
}


struct DraggableCircles: View {
    
    @State private var location: CGPoint = CGPoint(x: 500, y: 500)
    @GestureState private var startLocation: CGPoint? = nil
    
    var body: some View {
        
        // Here is create DragGesture and handel jump when you again start the dragging/
        let dragGesture = DragGesture()
            .onChanged { value in
                var newLocation = startLocation ?? location
                newLocation.x += value.translation.width
                newLocation.y += value.translation.height
                self.location = newLocation
            }.updating($startLocation) { (value, startLocation, transaction) in
                startLocation = startLocation ?? location
            }
        
        return ZStack {
            Color.white
            AppContentView()
                }
            .frame(width: 500, height: 500)
            .cornerRadius(10)
            .position(location)
            .gesture(dragGesture)
            .shadow(radius: 25)
    }
}




class getdata {
    func getdefaultsdata(type: String) -> String {
        let defaults = UserDefaults.standard
        let type = defaults.string(forKey: "\(type)")
        return type ?? ""
    }
    func savedefaultsdata(type: String, data: String) -> Void {
        let defaults = UserDefaults.standard
        defaults.set(data, forKey: "\(type)")
    }
    
    func getdefaultsdatabool(type: String) -> Bool {
        let defaults = UserDefaults.standard
        let type = defaults.bool(forKey: "\(type)")
        return type
    }
    func savedefaultsdatabool(type: String, data: Bool) -> Void {
        let defaults = UserDefaults.standard
        defaults.set(data, forKey: "\(type)")
    }
    
    func getdefaultsdataint(type: String) -> Int {
        let defaults = UserDefaults.standard
        let type = defaults.integer(forKey: "\(type)")
        return type
    }
    func savedefaultsdataint(type: String, data: Int) -> Void {
        let defaults = UserDefaults.standard
        defaults.set(data, forKey: "\(type)")
    }
    
    func getdata(date: String, datanum: Int) -> String {
        let defaults = UserDefaults.standard
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let date = dateFormatter.date(from: date)
        
        let today = date
        let formatter1 = DateFormatter()
        formatter1.dateFormat = "dd/MM/yyyy"
        let datedatanow = "\(formatter1.string(from: today ?? Date()))"
        let dataitem1 = defaults.string(forKey: "\(datedatanow)dataitem1")
        let dataitem2 = defaults.string(forKey: "\(datedatanow)dataitem2")
        let dataitem3 = defaults.string(forKey: "\(datedatanow)dataitem3")
        let dataitem4 = defaults.string(forKey: "\(datedatanow)dataitem4")
        //let dataholiday = defaults.bool(forKey: "\(datedatanow)dataholiday")
        let datacal1 = defaults.string(forKey: "\(datedatanow)datacal1")
        let datacal2 = defaults.string(forKey: "\(datedatanow)datacal2")
        let datacal3 = defaults.string(forKey: "\(datedatanow)datacal3")
        let datacal4 = defaults.string(forKey: "\(datedatanow)datacal4")
        
        //let holiday = dataholiday
        let item1 = dataitem1 ?? "N/A"
        let item2 = dataitem2 ?? "N/A"
        let item3 = dataitem3 ?? "N/A"
        let item4 = dataitem4 ?? "N/A"
        let cal1 = datacal1 ?? "N/A"
        let cal2 = datacal2 ?? "N/A"
        let cal3 = datacal3 ?? "N/A"
        let cal4 = datacal4 ?? "N/A"
        let alldata = ["(nil : N/A)", item1, item2, item3, item4, cal1, cal2, cal3, cal4]
        
        return alldata[datanum]
    }
    func savedata(date: String, datanum: Int, text: String) -> Void {
        let defaults = UserDefaults.standard
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let date = dateFormatter.date(from: date)
        
        let today = date
        let formatter1 = DateFormatter()
        formatter1.dateFormat = "dd/MM/yyyy"
        let datedatanow = "\(formatter1.string(from: today!))"
        
        if datanum == 0 {
            defaults.set(text, forKey: "\(datedatanow)dataitem1")
        }
        if datanum == 1 {
            defaults.set(text, forKey: "\(datedatanow)dataitem2")
        }
        if datanum == 2 {
            defaults.set(text, forKey: "\(datedatanow)dataitem3")
        }
        if datanum == 3 {
            defaults.set(text, forKey: "\(datedatanow)dataitem4")
        }
        if datanum == 4 {
            defaults.set(text, forKey: "\(datedatanow)datacal1")
        }
        if datanum == 5 {
            defaults.set(text, forKey: "\(datedatanow)datacal2")
        }
        if datanum == 6 {
            defaults.set(text, forKey: "\(datedatanow)datacal3")
        }
        if datanum == 7 {
            defaults.set(text, forKey: "\(datedatanow)datacal4")
        }
    }
    func clear() -> Void {
        let defaults = UserDefaults.standard
        let dictionary = defaults.dictionaryRepresentation()
        dictionary.keys.forEach { key in
            defaults.removeObject(forKey: key)
        }
    }
}

