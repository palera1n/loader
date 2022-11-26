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
                .padding(.bottom, 25)
            
            Spacer()
                .frame(maxHeight: !splash ? 0 : .infinity)
                .padding([.top, .horizontal])
                .padding(.bottom, 25)
            
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
                ForEach(self.console.consoleData) { item in
                    logItemView(item)
                        .padding(.bottom, 1)
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
    
    private func strap() -> Void {
        guard let tar = Bundle.main.path(forResource: "bootstrap", ofType: "tar") else {
            NSLog("[palera1n] Failed to find bootstrap")
            return
        }
         
        guard let helper = Bundle.main.path(forAuxiliaryExecutable: "palera1nHelper") else {
            NSLog("[palera1n] Could not find helper?")
            return
        }
         
        guard let deb = Bundle.main.path(forResource: "sileo", ofType: "deb") else {
            NSLog("[palera1n] Could not find Sileo")
            return
        }

        guard let libswift = Bundle.main.path(forResource: "libswift", ofType: "deb") else {
            NSLog("[palera1n] Could not find libswift")
            return
        }

        guard let safemode = Bundle.main.path(forResource: "safemode", ofType: "deb") else {
            NSLog("[palera1n] Could not find safemode")
            return
        }

        guard let preferenceloader = Bundle.main.path(forResource: "preferenceloader", ofType: "deb") else {
            NSLog("[palera1n] Could not find preferenceloader")
            return
        }

        guard let substitute = Bundle.main.path(forResource: "substitute", ofType: "deb") else {
            NSLog("[palera1n] Could not find substitute")
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
                    console.log("[-] Error installing bootstrap. Status: \(ret)")
                    return
                }
                
                console.log("[*] Preparing Bootstrap")
                DispatchQueue.global(qos: .utility).async {
                    let ret = spawn(command: "/usr/bin/sh", args: ["/prep_bootstrap.sh"], root: true)
                    DispatchQueue.main.async {
                        if ret != 0 {
                            console.log("[-] Failed to prepare bootstrap. Status: \(ret)")
                            return
                        }
                        
                        console.log("[*] Installing packages")
                        DispatchQueue.global(qos: .utility).async {
                            let ret = spawn(command: "/usr/bin/dpkg", args: ["-i", deb, libswift, safemode, preferenceloader, substitute], root: true)
                            DispatchQueue.main.async {
                                if ret != 0 {
                                    console.log("[-] Failed to install packages. Status: \(ret)")
                                    return
                                }
                                
                                console.log("[*] Registering Sileo in uicache")
                                DispatchQueue.global(qos: .utility).async {
                                    let ret = spawn(command: "/usr/bin/uicache", args: ["-p", "/Applications/Sileo.app"], root: true)
                                    DispatchQueue.main.async {
                                        if ret != 0 {
                                            console.log("[-] Failed to uicache. Status: \(ret)")
                                            return
                                        }
                                        console.log("[*] Finished installing! Enjoy!")
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

struct ToolbarController: View {
    var bs: () -> Void
    
    init(bootstrapAction: @escaping () -> Void) {
        self.bs = bootstrapAction
    }
    
    @State var settingsIsOpen = false
    @State var infoIsOpen = false
    
    @State var buttonBounds: CGSize? = nil
    
    var body: some View {
        HStack {
            Button {
                self.settingsIsOpen.toggle()
            } label: {
                Image(systemName: "gearshape.circle.fill")
                    .foregroundColor(.white)
                    .font(.largeTitle)
            }
            
            Button {
                self.bs()
            } label: {
                Text("Install")
                    .foregroundColor(.white)
                    .font(.subheadline)
            }
            
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
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .preferredColorScheme(.dark)
    }
}
