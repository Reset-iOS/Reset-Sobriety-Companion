import WidgetKit
import SwiftUI
import AppIntents
import Charts

struct UrgeLoggerWidgetEntry: TimelineEntry {
    let date: Date
    let urgeTimestamps: [Date]  // Store timestamps
}

struct UrgeLoggerWidgetProvider: TimelineProvider {
    func placeholder(in context: Context) -> UrgeLoggerWidgetEntry {
        UrgeLoggerWidgetEntry(date: Date(), urgeTimestamps: [])
    }

    func getSnapshot(in context: Context, completion: @escaping (UrgeLoggerWidgetEntry) -> Void) {
        let timestamps = fetchUrgeTimestamps()
        completion(UrgeLoggerWidgetEntry(date: Date(), urgeTimestamps: timestamps))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<UrgeLoggerWidgetEntry>) -> Void) {
        let timestamps = fetchUrgeTimestamps()
        let entry = UrgeLoggerWidgetEntry(date: Date(), urgeTimestamps: timestamps)
        completion(Timeline(entries: [entry], policy: .never))
    }

    private func fetchUrgeTimestamps() -> [Date] {
        let sharedDefaults = UserDefaults(suiteName: "group.com.reset.urges")
        let timestamps = sharedDefaults?.array(forKey: "urgeTimestamps") as? [Date] ?? []
        let lastSynced = sharedDefaults?.object(forKey: "lastSynced") as? Date ?? Date.distantPast

        // If urges were recently synced, assume no data loss
        if timestamps.isEmpty && Date().timeIntervalSince(lastSynced) < 30 { // 30 seconds buffer
            return [lastSynced] // Use last synced time as placeholder
        }

        return timestamps
    }
}

struct UrgeLoggerWidgetView: View {
    var entry: UrgeLoggerWidgetEntry
    
    var body: some View {
        if #available(iOSApplicationExtension 17.0, *) {
            VStack(spacing: 12) {
                // Header Section
                HStack {
                    Text("Urge Tracker")
                        .font(.system(.headline, design: .rounded))
                        .foregroundColor(.primary)
                    Spacer()
                    Button(intent: LogUrgeIntent()) {
                        HStack(spacing: 4) {
                            Image(systemName: "plus.circle.fill")
                            Text("Log")
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(
                            Capsule()
                                .fill(Color.red.opacity(0.9))
                        )
                        .foregroundColor(.white)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                
                // Chart Section
                VStack(alignment: .leading, spacing: 8) {
                    Text("Today's Progress")
                        .font(.system(.subheadline, design: .rounded))
                        .foregroundColor(.secondary)
                    
                    if entry.urgeTimestamps.isEmpty {
                        VStack(spacing: 6) {
                            Image(systemName: "chart.line.uptrend.xyaxis")
                                .font(.largeTitle)
                                .foregroundColor(.gray.opacity(0.3))
                            Text("No data yet")
                                .font(.system(.caption, design: .rounded))
                                .foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 120)
                    } else {
                        Chart(entry.urgeTimestamps, id: \.self) { timestamp in
                            LineMark(
                                x: .value("Time", timestamp),
                                y: .value("Count", entry.urgeTimestamps.filter { $0 <= timestamp }.count)
                            )
                            .interpolationMethod(.catmullRom)
                            .lineStyle(StrokeStyle(lineWidth: 2.5, lineCap: .round, lineJoin: .round))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.blue, .purple],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            
                            AreaMark(
                                x: .value("Time", timestamp),
                                y: .value("Count", entry.urgeTimestamps.filter { $0 <= timestamp }.count)
                            )
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.blue.opacity(0.2), .purple.opacity(0.1)],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                        }
                        .chartYAxis {
                            AxisMarks(position: .leading) { value in
                                AxisGridLine()
                                    .foregroundStyle(.gray.opacity(0.2))
                                AxisValueLabel()
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .chartXAxis {
                            AxisMarks { value in
                                AxisGridLine()
                                    .foregroundStyle(.gray.opacity(0.2))
                            }
                        }
                        .frame(height: 120)
                    }
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 24)
                    .fill(Color(.systemBackground))
                    .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
            )
            .widgetBackground()
        } else {
            VStack(spacing: 8) {
                Image(systemName: "exclamationmark.triangle")
                    .font(.title2)
                    .foregroundColor(.orange)
                Text("Update iOS for full widget support")
                    .font(.system(.callout, design: .rounded))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding()
            .widgetBackground()
        }
    }
}

// Extension for older iOS versions
extension View {
    @ViewBuilder
    func widgetBackground() -> some View {
        if #available(iOSApplicationExtension 17.0, *) {
            self.containerBackground(.fill.tertiary, for: .widget)
        } else {
            self.background(Color(.systemGray6)) // Fallback for older iOS versions
        }
    }
}

@main
struct UrgeLoggerWidget: Widget {
    let kind: String = "UrgeLoggerWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: UrgeLoggerWidgetProvider()) { entry in
            UrgeLoggerWidgetView(entry: entry)
        }
        .configurationDisplayName("Urge Logger")
        .description("Tap to log an urge and track your progress over time.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}
