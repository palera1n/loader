//
//  ContentView.swift
//  palera1nLoader
//
//  Created by Lakhan Lothiyi on 11/11/2022.
//

import SwiftUI
import SDWebImageSwiftUI

struct ContentView: View {
    @StateObject var console = Console()
    @State var bounds: CGSize? = nil

    private var serverURL = "https://static.palera.in/rootless"
    
    var body: some View {
        GeometryReader { geo in
            ZStack {
                LinearGradient(gradient: Gradient(colors: [.init(hex: "071B33"), .init(hex: "833F46"), .init(hex: "FFB123")]), startPoint: .topTrailing, endPoint: .bottomLeading)
                    .ignoresSafeArea()
                content
                    .onAppear {
                        self.bounds = geo.size
                        self.splashTimeout = Timer.scheduledTimer(withTimeInterval: 1, repeats: false) { _ in
                            withAnimation(.spring()) {
                                splash = false
                            }
                            
                            let d = HostManager.self
                            let machinename = d.getModelName() ?? "Unknown"
                            let modelarch = d.getModelArchitecture() ?? "Unknown"
                            let platformname = d.getPlatformName() ?? "Unknown"
                            let platformver = d.getPlatformVersion() ?? "Unknown"
                            
                            console.log("Welcome to palera1n loader")
                            console.log(uname())
                            console.log("\(machinename) running \(platformname) \(platformver) (\(modelarch))")
                        }
                    }
            }
        }
        .environmentObject(console)
    }
    
    @State var splash = true
    @State var splashTimeout: Timer? = nil
    
    @ViewBuilder
    var content: some View {
        VStack {
            titlebar
                .padding(.top, 20)
            
            consoleview
                .opacity(splash ? 0 : 1)
                .frame(maxHeight: splash ? 0 : .infinity)
                .padding([.top, .horizontal])
                .padding(.bottom, 20)
            
            Spacer()
                .frame(maxHeight: !splash ? 0 : .infinity)
                .padding([.top, .horizontal])
                .padding(.bottom, 20)
            
            toolbar
        }
        .foregroundColor(.white)
        .padding()
        .padding(.bottom)
        .padding(.vertical, 20)
    }
    
    @ViewBuilder
    var titlebar: some View {
        VStack {
            HStack {
                Image("palera1n-white")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 64)
                Text("palera1n")
                    .font(.system(size: 48, weight: .bold))
            }
            .padding(8)
        }
    }
    
    @ViewBuilder
    var consoleview: some View {
        VStack {
            ScrollView {
                ScrollViewReader { scroll in
                    ForEach(0..<self.console.consoleData.count, id: \.self) { i in
                        let item = self.console.consoleData[i]
                        logItemView(item)
                            .padding(.bottom, 1)
                    }
                    .onChange(of: self.console.consoleData.count) { newValue in
                        scroll.scrollTo(self.console.consoleData.count - 1)
                    }
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: splash ? 0 : ( bounds?.height ?? 1 / 1.9 ))
        .background(Color("CellBackground"))
        .cornerRadius(20)
        .padding(.bottom)
    }
    
    @ViewBuilder
    func logItemView(_ item: LogItem) -> some View {
        HStack {
            Text(item.string)
                .foregroundColor(Console.logTypeToColor(item.type))
                .font(.custom("Menlo", size: 12))
            Spacer()
        }
    }
    
    @ViewBuilder
    var toolbar: some View {
        ToolbarController {
            console.log("[*] Starting bootstrap process")
            strap()
        }
    }

    private func deleteFile(file: String) -> Void {
        let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let fileURL = documentsURL.appendingPathComponent(file)
        try? FileManager.default.removeItem(at: fileURL)
    }

    private func downloadFile(file: String, tb: ToolbarStateMoment) -> Void {
        console.log("[*] Downloading \(file)")
        deleteFile(file: file)

        let url = URL(string: "\(serverURL)/\(file)")!
        let task = URLSession.shared.downloadTask(with: url) { location, response, error in
        guard let location = location, error == nil else { return }
            do {
                let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
                let fileURL = documentsURL.appendingPathComponent(file)
                try FileManager.default.moveItem(at: location, to: fileURL)
                let tar = fileURL.path

                DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                    UIApplication.shared.perform(#selector(NSXPCConnection.suspend))
                }
            } catch {
                console.error("[-] Failed to download \(file): \(error)")
                NSLog("[palera1n] Failed to download \(file): \(error)")
                tb.toolbarState = .closeApp
            }
        }
        task.resume()
    }
    
    private func strap() -> Void {
        let tb = ToolbarStateMoment.s
        tb.toolbarState = .disabled
         
        guard let helper = Bundle.main.path(forAuxiliaryExecutable: "palera1nHelper") else {
            let msg = "Could not find helper?"
            console.error("[-] \(msg)")
            tb.toolbarState = .closeApp
            print("[palera1n] \(msg)")
            return
        }

        downloadFile(file: "bootstrap.tar", tb: tb)
        downloadFile(file: "sileo.deb", tb: tb)
        downloadFile(file: "preferenceloader.deb", tb: tb)
        downloadFile(file: "ellekit.deb", tb: tb)

        guard let tar = Bundle.main.path(forResource: "bootstrap", ofType: "tar") else {
            let msg = "Failed to find bootstrap"
            console.error("[-] \(msg)")
            tb.toolbarState = .closeApp
            print("[palera1n] \(msg)")
            return
        }

        guard let deb = Bundle.main.path(forResource: "sileo", ofType: "deb") else {
            let msg = "Could not find Sileo"
            console.error("[-] \(msg)")
            tb.toolbarState = .closeApp
            print("[palera1n] \(msg)")
            return
        }
        
        guard let ellekit = Bundle.main.path(forResource: "ellekit", ofType: "deb") else {
            let msg = "Could not find ElleKit"
            console.error("[-] \(msg)")
            tb.toolbarState = .closeApp
            print("[palera1n] \(msg)")
            return
        }
        
        guard let preferenceloader = Bundle.main.path(forResource: "preferenceloader", ofType: "deb") else {
            let msg = "Could not find PreferenceLoader"
            console.error("[-] \(msg)")
            tb.toolbarState = .closeApp
            print("[palera1n] \(msg)")
            return
        }
        
        DispatchQueue.global(qos: .utility).async { [self] in
            spawn(command: "/sbin/mount", args: ["-uw", "/private/preboot"], root: true)
            
            let ret = spawn(command: helper, args: ["-i", tar], root: true)
            
            spawn(command: "/var/jb/usr/bin/chmod", args: ["4755", "/var/jb/usr/bin/sudo"], root: true)
            spawn(command: "/var/jb/usr/bin/chown", args: ["root:wheel", "/var/jb/usr/bin/sudo"], root: true)
            
            DispatchQueue.main.async {
                if ret != 0 {
                    console.error("[-] Error installing bootstrap. Status: \(ret)")
                    tb.toolbarState = .closeApp
                    return
                }
                
                console.log("[*] Preparing Bootstrap")
                DispatchQueue.global(qos: .utility).async {
                    let ret = spawn(command: "/var/jb/usr/bin/sh", args: ["/var/jb/prep_bootstrap.sh"], root: true)
                    DispatchQueue.main.async {
                        if ret != 0 {
                            console.error("[-] Failed to prepare bootstrap. Status: \(ret)")
                            tb.toolbarState = .closeApp
                            return
                        }
                        
                        console.log("[*] Installing packages")
                        DispatchQueue.global(qos: .utility).async {
                            let ret = spawn(command: "/var/jb/usr/bin/dpkg", args: ["-i", deb, ellekit, preferenceloader], root: true)
                            DispatchQueue.main.async {
                                if ret != 0 {
                                    console.error("[-] Failed to install packages. Status: \(ret)")
                                    tb.toolbarState = .closeApp
                                    return
                                }

                                console.log("[*] Running uicache")
                                DispatchQueue.global(qos: .utility).async {
                                    let ret = spawn(command: "/var/jb/usr/bin/uicache", args: ["-a"], root: true)
                                    DispatchQueue.main.async {
                                        if ret != 0 {
                                            console.error("[-] Failed to uicache. Status: \(ret)")
                                            tb.toolbarState = .closeApp
                                            return
                                        }

                                        console.log("[*] Finished installing! Enjoy!")
                                        tb.toolbarState = .respring
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}

class ToolbarStateMoment: ObservableObject {
    static let s = ToolbarStateMoment()
    
    @Published var toolbarState: ToolbarController.ToolbarState = .toolbar
}

struct ToolbarController: View {
    var bs: () -> Void
    
    init(bootstrapAction: @escaping () -> Void) {
        self.bs = bootstrapAction
    }
    
    @State var settingsIsOpen = false
    @State var infoIsOpen = false
    
    @State var buttonBounds: CGSize? = nil
    
    @ObservedObject var state = ToolbarStateMoment.s
    
    public enum ToolbarState {
        case toolbar
        case disabled
        case closeApp
        case respring
    }
    
    var body: some View {
        VStack {
            switch state.toolbarState {
            case .toolbar:
                toolbar
            case .disabled:
                disabled
            case .closeApp:
                closeApp
            case .respring:
                respring
            }
        }
        .animation(.easeInOut, value: state.toolbarState)
    }
    
    @ViewBuilder
    var toolbar: some View {
        HStack {
            Button {
                self.settingsIsOpen.toggle()
            } label: {
                Image(systemName: "gearshape.circle.fill")
                    .foregroundColor(.white)
                    .font(.largeTitle)
            }
            .sheet(isPresented: $settingsIsOpen) {
                SettingsSheetView(isOpen: $settingsIsOpen)
            }
            
            Button {
                self.bs()
            } label: {
                Text("Install")
                    .foregroundColor(.init(hex: "68431f"))
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .padding(8)
                    .background(Capsule().foregroundColor(.white))
            }
            .buttonStyle(.plain)
            
            Button {
                self.infoIsOpen.toggle()
            } label: {
                Image(systemName: "info.circle.fill")
                    .foregroundColor(.white)
                    .font(.largeTitle)
            }
            .sheet(isPresented: $infoIsOpen) {
                CreditsSheetView(isOpen: $infoIsOpen)
            }
        }
        .padding()
        .background(
            Capsule()
                .foregroundColor(.init("CellBackground"))
        )
    }
    
    @ViewBuilder
    var disabled: some View {
        EmptyView()
    }
    
    @ViewBuilder
    var closeApp: some View {
        Button {
            fatalError()
        } label: {
            Text("Close")
                .font(.body)
                .foregroundLinearGradient(colors: [.init(hex: "071B33"), .init(hex: "833F46"), .init(hex: "FFB123")], startPoint: .leading, endPoint: .trailing)
                .frame(maxWidth: .infinity)
                .padding()
                .background {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                }
        }
        .buttonStyle(.plain)
        .padding()
        .padding(.horizontal)
        .frame(maxHeight: 30)
    }
    
    @ViewBuilder
    var respring: some View {
        Button {
            utils.respring()
        } label: {
            Text("Respring")
                .font(.body)
                .foregroundLinearGradient(colors: [.init(hex: "071B33"), .init(hex: "833F46"), .init(hex: "FFB123")], startPoint: .leading, endPoint: .trailing)
                .frame(maxWidth: .infinity)
                .padding()
                .background {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                }
        }
        .buttonStyle(.plain)
        .padding()
        .padding(.horizontal)
        .frame(maxHeight: 30)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .preferredColorScheme(.dark)
    }
}
