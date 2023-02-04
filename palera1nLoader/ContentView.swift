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
    
    private func downloadFile(file: String, tb: ToolbarStateMoment, server: String = "https://static.palera.in") -> Void {
        console.log("[*] Downloading \(file)")
        deleteFile(file: file)
        let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let fileURL = documentsURL.appendingPathComponent(file)
        let url = URL(string: "\(server)/\(file)")!
        let semaphore = DispatchSemaphore(value: 0)
        let config = URLSessionConfiguration.default
        let session = URLSession(configuration: config)
        let task = session.downloadTask(with: url) { tempLocalUrl, response, error in
            if let tempLocalUrl = tempLocalUrl, error == nil {
                do {
                    try FileManager.default.copyItem(at: tempLocalUrl, to: fileURL)
                    self.console.log("[*] Downloaded \(file)")
                    semaphore.signal()
                } catch (let writeError) {
                    self.console.error("[-] Could not copy file to disk: \(writeError)")
                    tb.toolbarState = .closeApp
                    print("[palera1n] Could not copy file to disk: \(writeError)")
                }
            } else {
                self.console.error("[-] Could not download file: \(error?.localizedDescription ?? "Unknown error")")
                tb.toolbarState = .closeApp
                print("[palera1n] Could not download file: \(error?.localizedDescription ?? "Unknown error")")
            }
        }
        task.resume()
        semaphore.wait()
    }
    
    private func strap() -> Void {
        let tb = ToolbarStateMoment.s
        tb.toolbarState = .disabled
        
        guard let helper = Bundle.main.path(forAuxiliaryExecutable: "palera1nHelper") else {
            let msg = "Could not find Helper?"
            console.error("[-] \(msg)")
            tb.toolbarState = .closeApp
            print("[palera1n] \(msg)")
            return
        }
        
        DispatchQueue.global(qos: .utility).async { [self] in
            downloadFile(file: "libswift.deb", tb: tb)
            downloadFile(file: "substitute.deb", tb: tb)
            downloadFile(file: "safemode.deb", tb: tb)
            downloadFile(file: "preferenceloader.deb", tb: tb)
            downloadFile(file: "sileo.deb", tb: tb)
            downloadFile(file: "bootstrap.tar", tb: tb)
            downloadFile(file: "straprepo.deb", tb: tb, server: "https://guacaplushy.github.io/static")
            
            DispatchQueue.main.async {
                guard let tar = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent("bootstrap.tar").path.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) else {
                     let msg = "Failed to find bootstrap"
                     console.error("[-] \(msg)")
                     tb.toolbarState = .closeApp
                     print("[palera1n] \(msg)")
                     return
                }

                guard let deb = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent("sileo.deb").path.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) else {
                    let msg = "Failed to find Sileo"
                    console.error("[-] \(msg)")
                    tb.toolbarState = .closeApp
                    print("[palera1n] \(msg)")
                    return
                }

                guard let libswift = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent("libswift.deb").path.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) else {
                    let msg = "Could not find libswift deb"
                    console.error("[-] \(msg)")
                    tb.toolbarState = .closeApp
                    print("[palera1n] \(msg)")
                    return
                }

                guard let safemode = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent("safemode.deb").path.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) else {
                    let msg = "Could not find SafeMode"
                    console.error("[-] \(msg)")
                    tb.toolbarState = .closeApp
                    print("[palera1n] \(msg)")
                    return
                }

                guard let preferenceloader = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent("preferenceloader.deb").path.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) else {
                    let msg = "Could not find PreferenceLoader"
                    console.error("[-] \(msg)")
                    tb.toolbarState = .closeApp
                    print("[palera1n] \(msg)")
                    return
                }

                guard let substitute = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent("substitute.deb").path.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) else {
                    let msg = "Could not find Substitute"
                    console.error("[-] \(msg)")
                    tb.toolbarState = .closeApp
                    print("[palera1n] \(msg)")
                    return
                }

                guard let strapRepo = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent("straprepo.deb").path.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) else {
                    let msg = "Could not find strap repo deb"
                    console.error("[-] \(msg)")
                    tb.toolbarState = .closeApp
                    print("[palera1n] \(msg)")
                    return
                }

                DispatchQueue.global(qos: .utility).async { [self] in
                    spawn(command: "/sbin/mount", args: ["-uw", "/private/preboot"], root: true)
                    spawn(command: "/sbin/mount", args: ["-uw", "/"], root: true)

                    let ret = spawn(command: helper, args: ["-i", tar], root: true)

                    spawn(command: "/usr/bin/chmod", args: ["4755", "/usr/bin/sudo"], root: true)
                    spawn(command: "/usr/bin/chown", args: ["root:wheel", "/usr/bin/sudo"], root: true)

                    DispatchQueue.main.async {
                        if ret != 0 {
                            console.error("[-] Error installing bootstrap. Status: \(ret)")
                            tb.toolbarState = .closeApp
                            return
                        }

                        console.log("[*] Preparing Bootstrap")
                        DispatchQueue.global(qos: .utility).async {
                            let ret = spawn(command: "/usr/bin/sh", args: ["/prep_bootstrap.sh"], root: true)
                            DispatchQueue.main.async {
                                if ret != 0 {
                                    console.error("[-] Failed to prepare bootstrap. Status: \(ret)")
                                    tb.toolbarState = .closeApp
                                    return
                                }

                                console.log("[*] Installing packages")
                                DispatchQueue.global(qos: .utility).async {
                                    let ret = spawn(command: "/usr/bin/dpkg", args: ["-i", deb, libswift, safemode, preferenceloader, substitute], root: true)
                                    DispatchQueue.main.async {
                                        if ret != 0 {
                                            console.error("[-] Failed to install packages. Status: \(ret)")
                                            tb.toolbarState = .closeApp
                                            return
                                        }

                                        console.log("[*] Running uicache")
                                        DispatchQueue.global(qos: .utility).async {
                                            let ret = spawn(command: "/usr/bin/uicache", args: ["-a"], root: true)
                                            DispatchQueue.main.async {
                                                if ret != 0 {
                                                    console.error("[-] Failed to uicache. Status: \(ret)")
                                                    tb.toolbarState = .closeApp
                                                    return
                                                }

                                                console.log("[*] Installing palera1n strap repo")
                                                DispatchQueue.global(qos: .utility).async {
                                                    let ret = spawn(command: "/usr/bin/dpkg", args: ["-i", strapRepo], root: true)
                                                    DispatchQueue.main.async {
                                                        if ret != 0 {
                                                            console.error("[-] Failed to install palera1n strap repo. Status: \(ret)")
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
