import SwiftUI
import AVFoundation
import Keyboard

struct ContentView: View {

    @StateObject var core = HiSynthCore()

    init() {
        Fonts.registerAllFonts()
    }
    
    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                VStack {
                    HStack(alignment: .bottom) {
                        Spacer()
                        Text("Welcome to")
                            .modifier(HSFont(.title1))
                        Text("HiSynth")
                            .modifier(HSFont(.artTitle1))
                        Spacer()
                    }.foregroundColor(.white)
                    Spacer()
                }
                HStack{
                    Spacer()
                }.frame(height: 60)
                 .background(Color(hex: 0x333333))
                 .border(.black, width: 2)
                VStack {
                   KeyboardView(core: core)
                }
            }.background(LinearGradient(gradient: Gradient(colors: [Color(hex: 0x4a4a4a), Color(hex: 0x000000)]),
                                        startPoint: .top, endPoint: .bottom))
        }
    }
}

struct ContentViewPreviewProvider: PreviewProvider {
    static var previews: some View {
        ContentView()
            .previewInterfaceOrientation(.landscapeLeft)
            .previewDevice(PreviewDevice(rawValue: "iPad Pro (11-inch)"))
    }
}