//
//  InclinometerView.swift
//  Log
//
//  Created by Giovanni Jr Di Fenza on 21/05/25.
//

import SwiftUI
import CoreMotion

struct InclinometerView: View {
    var angle: Double
    var axisLabel: String
    var mode: MeasurementMode
    
    var body: some View {
        ZStack {
            // Clinometer background
            Circle()
                .stroke(Color.gray.opacity(0.5), lineWidth: 4)
                .shadow(color: Color.black.opacity(0.2), radius: 5, x: 0, y: 2)
                .background(Circle().fill(
                    LinearGradient(gradient: Gradient(colors: [Color.gray.opacity(0.1), Color.white.opacity(0.9)]),
                                  startPoint: .topLeading,
                                  endPoint: .bottomTrailing))
                )
            
            // Reference lines
            ForEach(0..<37) { i in
                if i % 9 == 0 {
                    Rectangle()
                        .fill(Color.black)
                        .frame(width: 3, height: 20)
                        .offset(y: -130)
                        .rotationEffect(.degrees(Double(i) * 10))
                } else if i % 3 == 0 {
                    Rectangle()
                        .fill(Color.black.opacity(0.7))
                        .frame(width: 2, height: 15)
                        .offset(y: -130)
                        .rotationEffect(.degrees(Double(i) * 10))
                } else {
                    Rectangle()
                        .fill(Color.gray.opacity(0.5))
                        .frame(width: 1, height: 10)
                        .offset(y: -130)
                        .rotationEffect(.degrees(Double(i) * 10))
                }
            }
            
            // Angular labels
            ForEach(0..<7) { i in
                Text("\(i * 15)°")
                    .font(.caption)
                    .foregroundColor(.black)
                    .offset(y: -110)
                    .rotationEffect(.degrees(Double(i) * 45))
            }
            
            // Safe zone indicators (customized per mode)
            if mode == .treeLean {
                // Green area for acceptable tree lean
                Circle()
                    .trim(from: 0.475, to: 0.525)
                    .stroke(Color.green.opacity(0.3), lineWidth: 40)
                    .rotationEffect(.degrees(90))
                
                // Yellow area for moderate tree lean
                Circle()
                    .trim(from: 0.45, to: 0.475)
                    .stroke(Color.yellow.opacity(0.3), lineWidth: 40)
                    .rotationEffect(.degrees(90))
                Circle()
                    .trim(from: 0.525, to: 0.55)
                    .stroke(Color.yellow.opacity(0.3), lineWidth: 40)
                    .rotationEffect(.degrees(90))
            } else if mode == .slopeGrade {
                // Green area for gentle slopes
                Circle()
                    .trim(from: 0.45, to: 0.55)
                    .stroke(Color.green.opacity(0.3), lineWidth: 30)
                    .rotationEffect(.degrees(90))
                
                // Yellow area for moderate slopes
                Circle()
                    .trim(from: 0.4, to: 0.45)
                    .stroke(Color.yellow.opacity(0.3), lineWidth: 30)
                    .rotationEffect(.degrees(90))
                Circle()
                    .trim(from: 0.55, to: 0.6)
                    .stroke(Color.yellow.opacity(0.3), lineWidth: 30)
                    .rotationEffect(.degrees(90))
            }
            
            // Clinometer line
            Rectangle()
                .fill(
                    LinearGradient(gradient: Gradient(colors: [Color.red, Color.red.opacity(0.7)]),
                                  startPoint: .top,
                                  endPoint: .bottom)
                )
                .frame(width: 4, height: 120)
                .offset(y: -60)
                .rotationEffect(.degrees(mode == .treeHeight ? angle : -angle))
                .shadow(color: Color.black.opacity(0.5), radius: 1, x: 0, y: 0)
            
            // Center point
            Circle()
                .fill(
                    RadialGradient(gradient: Gradient(colors: [Color.red.opacity(0.8), Color.red]),
                                  center: .center,
                                  startRadius: 0,
                                  endRadius: 10)
                )
                .frame(width: 20, height: 20)
                .shadow(color: Color.black.opacity(0.5), radius: 2, x: 0, y: 1)
            
            // Angle value and axis indication
            VStack {
                Text(String(format: "%.1f°", abs(angle)))
                    .font(.title)
                    .fontWeight(.bold)
                
                if mode == .treeHeight {
                    Text("Angolo di elevazione")
                        .font(.caption)
                        .foregroundColor(.gray)
                } else {
                    Text("Asse \(axisLabel)")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                
                Text(getModeText())
                    .font(.caption2)
                    .foregroundColor(.blue)
            }
            .offset(y: 60)
        }
    }
    
    private func getModeText() -> String {
        switch mode {
        case .treeLean:
            return "Inclinazione dell'albero"
        case .slopeGrade:
            return "Pendenza del terreno"
        case .treeHeight:
            return "Misurazione altezza"
        }
    }
}
