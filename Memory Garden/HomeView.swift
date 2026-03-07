import SwiftUI

struct HomeView: View {
    @ObservedObject var store: MemoryStore
    
    @State private var showAddMemory = false

    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(
                    colors: [
                        Color(red: 0.10, green: 0.08, blue: 0.22),
                        Color(red: 0.45, green: 0.30, blue: 0.70),
                        Color(red: 0.95, green: 0.60, blue: 0.80)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                VStack(spacing: 16) {
                    header
                    Spacer()

                    PlanetCard(
                        plantedCount: store.planted.count,
                        memoriesCount: store.memories.count,
                        streakCount: memoryStreak(memories: store.memories)
                    )
                    .padding(.horizontal, 18)

                    Spacer()

                    VStack(spacing: 12) {
                        NavigationLink {
                            ContentView(store: store)
                        } label: {
                            HomeActionButton(title: "Open AR", subtitle: "Place in space", icon: "arkit")
                        }

                        Button {
                            showAddMemory = true
                        } label: {
                            HomePrimaryButton(title: "Plant a Memory", subtitle: "Text, photo, or voice", icon: "leaf.fill")
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.horizontal, 18)
                    .padding(.bottom, 18)
                }
            }
            .toolbar(.hidden, for: .navigationBar)
        }
        .task { store.load() } // ensures Home shows saved items too
        .sheet(isPresented: $showAddMemory) {
            AddMemoryView { memory in
                store.addMemory(memory)
                showAddMemory = false
            }
        }
    }

    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Your Garden")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)

                Text("Plant a memory today ✨")
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundStyle(.white.opacity(0.85))
            }
            Spacer()
        }
        .padding(.horizontal, 18)
        .padding(.top, 18)
    }

    private func streakPlaceholder() -> Int {
        // optional: compute later from memory dates
        0
    }
}
func memoryStreak(memories: [Memory], calendar: Calendar = .current) -> Int {
    let daysWithMemories: Set<Date> = Set(memories.map { calendar.startOfDay(for: $0.createdAt) })
    guard !daysWithMemories.isEmpty else { return 0 }

    var streak = 0
    var day = calendar.startOfDay(for: Date())

    while daysWithMemories.contains(day) {
        streak += 1
        guard let prev = calendar.date(byAdding: .day, value: -1, to: day) else { break }
        day = prev
    }
    return streak
}

private struct PlanetCard: View {
    let plantedCount: Int
    let memoriesCount: Int
    let streakCount: Int

    // how big the planet grows
    private var planetSize: CGFloat {
        // starts at 140, grows up to 220
        140 + CGFloat(min(memoriesCount, 20)) * 4
    }

    // how many “decor plants” to show around the planet
    private var decorCount: Int {
        min(memoriesCount, 12)
    }

    // pick a few cute plant emojis
    private let decorEmojis = ["🌱","🌸","🌼","🍀","🌿","🪴","✨"]

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 28)
                .fill(.white.opacity(0.12))
                .overlay(
                    RoundedRectangle(cornerRadius: 28)
                        .stroke(.white.opacity(0.20), lineWidth: 1)
                )
                .shadow(radius: 18)

            VStack(spacing: 14) {

                ZStack {
                    // soft glow bubble
                    Circle()
                        .fill(.white.opacity(0.10))
                        .frame(width: 240, height: 240)

                    // orbit ring
                    Circle()
                        .stroke(.white.opacity(0.20), style: StrokeStyle(lineWidth: 1, dash: [6, 8]))
                        .frame(width: 210, height: 210)

                    // the “planet” that grows
                    Circle()
                        .fill(.white.opacity(0.28))
                        .frame(width: planetSize, height: planetSize)
                        .overlay(
                            Circle().stroke(.white.opacity(0.25), lineWidth: 1)
                        )
                        .animation(.spring(response: 0.45, dampingFraction: 0.8), value: memoriesCount)

                    // little plants around the planet
                    ForEach(0..<decorCount, id: \.self) { i in
                        let angle = Double(i) / Double(max(decorCount, 1)) * (2 * Double.pi)
                        let radius: CGFloat = 120

                        Text(decorEmojis[i % decorEmojis.count])
                            .font(.system(size: 20))
                            .offset(
                                x: cos(angle) * radius,
                                y: sin(angle) * radius
                            )
                            .opacity(0.9)
                            .animation(.easeInOut(duration: 0.35), value: decorCount)
                    }

                    // tiny sparkle
                    Text("✨")
                        .font(.system(size: 18))
                        .offset(x: 88, y: -58)
                        .opacity(0.9)
                }
                .frame(height: 260)

                HStack(spacing: 10) {
                    StatPill(title: "Planted", value: "\(plantedCount)")
                    StatPill(title: "Memories", value: "\(memoriesCount)")
                    StatPill(title: "Streak", value: "\(streakCount)")
                }
            }
            .padding(18)
        }
        .frame(height: 360)
    }
}

private struct StatPill: View {
    let title: String
    let value: String

    var body: some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
            Text(title)
                .font(.system(size: 12, weight: .medium, design: .rounded))
                .foregroundStyle(.white.opacity(0.8))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background(.white.opacity(0.14))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(.white.opacity(0.18), lineWidth: 1)
        )
    }
}

private struct HomeActionButton: View {
    let title: String
    let subtitle: String
    let icon: String

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 16)
                    .fill(.white.opacity(0.16))
                    .frame(width: 48, height: 48)
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(.white)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white)
                Text(subtitle)
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundStyle(.white.opacity(0.8))
            }

            Spacer()
            Image(systemName: "chevron.right")
                .foregroundStyle(.white.opacity(0.8))
        }
        .padding(14)
        .background(.white.opacity(0.12))
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(.white.opacity(0.18), lineWidth: 1)
        )
    }
}

private struct HomePrimaryButton: View {
    let title: String
    let subtitle: String
    let icon: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: 46, height: 46)
                .background(.white.opacity(0.18))
                .clipShape(RoundedRectangle(cornerRadius: 16))

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 17, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                Text(subtitle)
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundStyle(.white.opacity(0.85))
            }

            Spacer()
            Image(systemName: "plus")
                .foregroundStyle(.white.opacity(0.85))
                .padding(.trailing, 6)
        }
        .padding(16)
        .background(.white.opacity(0.16))
        .clipShape(RoundedRectangle(cornerRadius: 22))
        .overlay(
            RoundedRectangle(cornerRadius: 22)
                .stroke(.white.opacity(0.18), lineWidth: 1)
        )
    }
}
