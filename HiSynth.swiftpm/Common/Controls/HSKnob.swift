//
//  HSKnob.swift
//
//
//  Created by Bill Chen on 2023/4/4.
//

import Foundation
import SwiftUI

struct HSKnob: View {
    @Binding var value: Float
    @State var isDragging = false
    @State var oldValue: Float = 0

    var range: ClosedRange<Float> = 0...1
    var size: CGFloat = 80.0

    /// Set if when value = 0, the signal light will be turned gray.
    var allowPoweroff = true

    /// Set the sensitivity of the dragging gesture.
    var sensitivity: Float = 0.3

    let startingAngle: Angle = .radians(.pi / 6)

    var normalizedValue: Float {
        Float((value - range.lowerBound) / (range.upperBound - range.lowerBound))
    }

    var body: some View {
        return ZStack{
            Circle()
                .shadow(color: Color(hex: 0x000000, alpha: 0.5), radius: 10.0, x: 0, y: 5)
                .foregroundStyle(Theme.gradientKnob.shadow(.inner(color: .white.opacity(0.5), radius: 8, x: 1, y: 5)))
                .frame(width: size, height: size)
            if allowPoweroff && normalizedValue == 0.0 {
                Circle()
                    .fill(Theme.colorGray4)
                    .frame(width: size / 12, height: size / 12.0)
                    .offset(y: size / 2.0 * 0.7)
                    .rotationEffect(startingAngle)
                    .rotationEffect((.radians(2 * .pi) - startingAngle * 2) * Double(normalizedValue))
            } else {
                Circle()
                    .fill(Theme.colorHighlight)
                    .shadow(color: Theme.colorHighlight, radius: 5.0)
                    .shadow(color: Theme.colorHighlight, radius: 10.0)
                    .frame(width: size / 12, height: size / 12.0)
                    .offset(y: size / 2.0 * 0.7)
                    .rotationEffect(startingAngle)
                    .rotationEffect((.radians(2 * .pi) - startingAngle * 2) * Double(normalizedValue))
            }
        }.gesture(DragGesture(minimumDistance: 0)
            .onChanged { value in
                updateValue(from: value)
            }
            .onEnded { _ in
                isDragging = false
            }
        )
    }

    private func updateValue(from value: DragGesture.Value) {
        if !isDragging {
            oldValue = self.value
            isDragging = true
        }
        let x = value.translation.width
        let y = -value.translation.height
        var offset: Float = 0.0
        offset += Float(x / size) * (range.upperBound - range.lowerBound) * sensitivity
        offset += Float(y / size) * (range.upperBound - range.lowerBound) * sensitivity
        self.value = max(range.lowerBound, min(range.upperBound, self.oldValue + offset))
    }
}


struct HSKnob_Container: View {
    @State var value: Float = 0.5
    var body: some View {
        HSKnob(value: $value)
    }
}

struct HSKnob_Previews: PreviewProvider {
    static var previews: some View {
        HSKnob_Container()
    }
}
