import SwiftUI
import Combine

class ClockState: ObservableObject {
    @Published var count: Double = 0
    @Published var isStopped = true
    @Published var showSettings = false
    @Published var config: Config = .stopwatch(startTime: 300)
    
    func updateCount(by val: Double) {
        count += val
    }
    
    func resetCount() {
        count = 0
    }
    
    // MARK: - Configuration
    
    enum Config {
        case timer(maxCountInSeconds: Int)
        case stopwatch(startTime: Int)
        
        var maxCount: Double {
            switch self {
            case .stopwatch(let maxCount),
                 .timer(let maxCount):
                return Double(maxCount)
            }
        }
        
        func minutes(from count: Double) -> Int {
            switch self {
            case .stopwatch:
                Int(count) / 60
            case .timer:
                Int(maxCount - count) / 60
            }
        }
        
        func seconds(from count: Double) -> Int {
            switch self {
            case .stopwatch:
                Int(count) % 60
            case .timer:
                Int(maxCount - count) % 60
            }
        }
    }
}

class ClockFlipViewModel: ObservableObject {
    
    // MARK: - Internal

    var foregroundColor: Color = .gray.opacity(0.9)
    var backgroundColor: Color = .primary
    
    var minutes: Int {
        config.minutes(from: clockState.count)
    }
    
    var seconds: Int {
        config.seconds(from: clockState.count)
    }
    
    var config: ClockState.Config {
        clockState.config
    }
    
    func updateColorScheme(_ colorScheme: ColorScheme) {
        foregroundColor = colorScheme == .dark ? .black.opacity(0.9) : .gray.opacity(0.9)
        backgroundColor = colorScheme == .dark ? .primary : .primary
    }
    
    let clockState: ClockState
    
    // MARK: - Init
    
    init(clockState: ClockState) {
        self.clockState = clockState
        setupTimer()
    }
    
    // MARK: - Private
    
    private let timer = Timer.publish(every: 0.01, on: .main, in: .common).autoconnect()
    private var cancellables = Set<AnyCancellable>()
    
    private func setupTimer() {
        timer
            .sink { [weak self] _ in
                guard let self,
                      !self.clockState.isStopped,
                      self.config.maxCount > self.clockState.count else { return }
                clockState.updateCount(by: 0.01)
            }
            .store(in: &cancellables)
    }
}
