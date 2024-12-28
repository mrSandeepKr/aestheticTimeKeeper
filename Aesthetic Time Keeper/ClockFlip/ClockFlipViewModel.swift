import SwiftUI
import Combine

class ClockState: ObservableObject {
    @Published var count: Double = 0
    @Published var isStopped = false
}

class ClockFlipViewModel: ObservableObject {
    
    // MARK: - Internal
    @ObservedObject var clockState: ClockState
    
    var minutes: Int {
        config.minutes(from: clockState.count)
    }
    
    var seconds: Int {
        config.seconds(from: clockState.count)
    }
    
    // MARK: - Init
    
    init(config: Config, clockState: ClockState) {
        self.config = config
        self.clockState = clockState
        setupTimer()
    }
    
    // MARK: - Private
    
    private let config: Config
    private let timer = Timer.publish(every: 0.01, on: .main, in: .common).autoconnect()
    private var cancellables = Set<AnyCancellable>()
    
    private func setupTimer() {
        timer
            .sink { [weak self] _ in
                guard let self,
                      !self.clockState.isStopped,
                      self.config.maxCount > self.clockState.count else { return }
                self.clockState.count += 0.01
            }
            .store(in: &cancellables)
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

#Preview {
    ClockFlipViewUsage(config: .stopwatch(startTime: 100))
        .preferredColorScheme(.light)
}
