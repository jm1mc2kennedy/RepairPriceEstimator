import Foundation

/// Service for managing jewelry inspection and condition assessment
@MainActor
final class InspectionService: ObservableObject {
    private let repository: DataRepository
    private let pricingEngine: PricingEngine
    
    @Published var isInspecting: Bool = false
    @Published var currentInspection: InProgressInspection?
    
    init(repository: DataRepository = CloudKitService.shared) {
        self.repository = repository
        self.pricingEngine = PricingEngine(repository: repository)
    }
    
    /// Start a new inspection for a piece of jewelry
    func startInspection(
        guestId: String,
        inspectorId: String,
        initialDescription: String
    ) async -> InProgressInspection {
        
        let inspection = InProgressInspection(
            guestId: guestId,
            inspectorId: inspectorId,
            initialDescription: initialDescription
        )
        
        currentInspection = inspection
        isInspecting = true
        
        print("🔍 Started inspection for guest: \(guestId)")
        return inspection
    }
    
    /// Add a condition finding to the current inspection
    func addFinding(
        category: ConditionCategory,
        severity: ConditionSeverity,
        description: String,
        location: String? = nil
    ) {
        guard var inspection = currentInspection else { return }
        
        let finding = ConditionFinding(
            category: category,
            severity: severity,
            description: description,
            recommendedServices: getRecommendedServices(for: category, severity: severity),
            location: location
        )
        
        inspection.findings.append(finding)
        
        // Update overall condition
        inspection.updateOverallCondition()
        
        // Check if safe to clean
        inspection.updateSafeToClean()
        
        currentInspection = inspection
        
        print("📝 Added finding: \(category.displayName) - \(severity.displayName)")
    }
    
    /// Complete the inspection and determine next steps
    func completeInspection() async throws -> InspectionResult {
        guard let inspection = currentInspection else {
            throw InspectionError.noActiveInspection
        }
        
        let result = try await processInspectionResults(inspection)
        
        // Clear current inspection
        currentInspection = nil
        isInspecting = false
        
        print("✅ Completed inspection with \(inspection.findings.count) findings")
        return result
    }
    
    /// Cancel the current inspection
    func cancelInspection() {
        currentInspection = nil
        isInspecting = false
        print("❌ Inspection cancelled")
    }
    
    // MARK: - Private Methods
    
    private func getRecommendedServices(for category: ConditionCategory, severity: ConditionSeverity) -> [String] {
        // Map condition categories to recommended service types
        switch category {
        case .stoneLoose:
            return ["STONE_TIGHTENING", "PRONG_RETIP"]
        case .prongWorn, .prongBent, .prongBroken:
            return ["PRONG_RETIP", "PRONG_REBUILD"]
        case .shankThin:
            return ["SHANK_THICKENING", "SHANK_REBUILD"]
        case .metalCrack, .metalBreak:
            return ["SOLDER_REPAIR", "JEWELRY_REBUILD"]
        case .channelWorn:
            return ["CHANNEL_REPAIR", "CHANNEL_REBUILD"]
        case .linkWorn, .linkStretched:
            return ["CHAIN_REPAIR", "LINK_REPLACEMENT"]
        case .finish:
            return ["RHODIUM_PLATING", "POLISHING", "REFINISHING"]
        case .sizing:
            return ["RING_SIZING_UP", "RING_SIZING_DOWN"]
        case .claspWorn, .bailWorn, .hingeWorn:
            return ["CLASP_REPAIR", "FINDING_REPLACEMENT"]
        default:
            return ["GENERAL_REPAIR"]
        }
    }
    
    private func processInspectionResults(_ inspection: InProgressInspection) async throws -> InspectionResult {
        // Determine if safe for cleaning
        let safeToClean = inspection.safeToClean && inspection.overallCondition != .unsafeToClean
        
        // Generate recommended actions
        var recommendedActions: [RecommendedAction] = []
        
        if safeToClean && inspection.findings.isEmpty {
            // No issues found - recommend cleaning
            recommendedActions.append(
                RecommendedAction(
                    type: .cleaning,
                    description: "Complimentary cleaning and inspection",
                    priority: .low,
                    serviceTypeIds: ["CLEANING"]
                )
            )
        } else if !safeToClean || inspection.hasSignificantFindings {
            // Issues found - recommend repair quote
            recommendedActions.append(
                RecommendedAction(
                    type: .repairQuote,
                    description: "Create repair quote for identified issues",
                    priority: inspection.overallCondition == .critical ? .urgent : .high,
                    serviceTypeIds: inspection.recommendedServices
                )
            )
            
            // Add specific recommendations for each finding
            for finding in inspection.findings where finding.severity != .minor {
                recommendedActions.append(
                    RecommendedAction(
                        type: .specificRepair,
                        description: "Address \(finding.category.displayName.lowercased())",
                        priority: finding.severity == .critical ? .urgent : .medium,
                        serviceTypeIds: finding.recommendedServices
                    )
                )
            }
        }
        
        // Create inspection checklist
        let checklist = IntakeChecklist(
            quoteId: "", // Will be set when quote is created
            inspectorId: inspection.inspectorId,
            inspectionDate: inspection.startTime,
            findings: inspection.findings,
            overallCondition: inspection.overallCondition,
            safeToClean: safeToClean,
            repairType: determineRepairType(from: inspection),
            shortDescription: inspection.initialDescription,
            extendedDescription: generateExtendedDescription(from: inspection),
            conditionNotes: generateConditionNotes(from: inspection)
        )
        
        return InspectionResult(
            inspection: inspection,
            checklist: checklist,
            safeToClean: safeToClean,
            recommendedActions: recommendedActions,
            requiresRepairQuote: !safeToClean || inspection.hasSignificantFindings
        )
    }
    
    private func determineRepairType(from inspection: InProgressInspection) -> ServiceCategory {
        // Determine primary repair type based on findings
        let categories = inspection.findings.map { $0.category }
        
        if categories.contains(where: { $0.rawValue.contains("WATCH") }) {
            return .watchService
        } else if categories.contains(where: { $0.rawValue.contains("STONE") || $0.rawValue.contains("PRONG") }) {
            return .jewelryRepair
        } else {
            return .jewelryRepair // Default
        }
    }
    
    private func generateExtendedDescription(from inspection: InProgressInspection) -> String {
        var description = inspection.initialDescription
        
        if !inspection.findings.isEmpty {
            description += "\n\nCondition Findings:\n"
            for finding in inspection.findings {
                let locationStr = finding.location.map { " (\($0))" } ?? ""
                description += "• \(finding.category.displayName)\(locationStr): \(finding.description)\n"
            }
        }
        
        return description
    }
    
    private func generateConditionNotes(from inspection: InProgressInspection) -> String {
        var notes = "Overall condition: \(inspection.overallCondition.displayName)"
        
        if !inspection.safeToClean {
            notes += "\n⚠️ NOT SAFE TO CLEAN - requires repair before cleaning"
        }
        
        let criticalFindings = inspection.findings.filter { $0.severity == .critical }
        if !criticalFindings.isEmpty {
            notes += "\n🚨 Critical issues requiring immediate attention:"
            for finding in criticalFindings {
                notes += "\n  • \(finding.description)"
            }
        }
        
        return notes
    }
}

/// In-progress inspection data
struct InProgressInspection: Sendable {
    let id: String
    let guestId: String
    let inspectorId: String
    let startTime: Date
    let initialDescription: String
    
    var findings: [ConditionFinding]
    var overallCondition: ConditionSeverity
    var safeToClean: Bool
    var notes: String
    
    init(
        guestId: String,
        inspectorId: String,
        initialDescription: String
    ) {
        self.id = UUID().uuidString
        self.guestId = guestId
        self.inspectorId = inspectorId
        self.startTime = Date()
        self.initialDescription = initialDescription
        self.findings = []
        self.overallCondition = .minor
        self.safeToClean = true
        self.notes = ""
    }
    
    /// Whether inspection has significant findings requiring repair
    var hasSignificantFindings: Bool {
        findings.contains { $0.severity == .major || $0.severity == .critical }
    }
    
    /// All recommended service IDs from findings
    var recommendedServices: [String] {
        findings.flatMap { $0.recommendedServices }.uniqued()
    }
    
    /// Update overall condition based on worst finding
    mutating func updateOverallCondition() {
        let worstSeverity = findings.map { $0.severity }.max { a, b in
            severityOrder(a) < severityOrder(b)
        } ?? .minor
        
        overallCondition = worstSeverity
    }
    
    /// Update safe to clean based on findings
    mutating func updateSafeToClean() {
        safeToClean = !findings.contains { finding in
            finding.severity == .unsafeToClean ||
            finding.category == .stoneLoose ||
            finding.category == .stoneFractureFilling ||
            finding.category == .prongBroken ||
            finding.category == .metalCrack
        }
    }
    
    private func severityOrder(_ severity: ConditionSeverity) -> Int {
        switch severity {
        case .minor: return 1
        case .moderate: return 2
        case .major: return 3
        case .critical: return 4
        case .unsafeToClean: return 5
        }
    }
}

/// Result of a completed inspection
struct InspectionResult: Sendable {
    let inspection: InProgressInspection
    let checklist: IntakeChecklist
    let safeToClean: Bool
    let recommendedActions: [RecommendedAction]
    let requiresRepairQuote: Bool
}

/// Recommended action based on inspection findings
struct RecommendedAction: Identifiable, Sendable {
    let id = UUID()
    let type: ActionType
    let description: String
    let priority: QuotePriority
    let serviceTypeIds: [String]
    
    enum ActionType {
        case cleaning
        case repairQuote
        case specificRepair
        case qualityCheck
        case vendorConsult
    }
}

// MARK: - Errors

enum InspectionError: Error, LocalizedError {
    case noActiveInspection
    case inspectionIncomplete
    case invalidFinding
    
    var errorDescription: String? {
        switch self {
        case .noActiveInspection:
            return "No active inspection in progress"
        case .inspectionIncomplete:
            return "Inspection must be completed before processing"
        case .invalidFinding:
            return "Invalid inspection finding data"
        }
    }
}
