import XCTest
@testable import Clarify

/// Guards the bundled guide and glossary catalog: every guide has a
/// level, every section covers the easy end, IDs stay unique and stable,
/// and every highlighted word in a step has a glossary card behind it.
final class CatalogTests: XCTestCase {

    // MARK: Guides

    func testGuideTitlesAreUnique() {
        let titles = WorkflowLibrary.all.map(\.title)
        XCTAssertEqual(Set(titles).count, titles.count, "Duplicate guide titles: \(duplicates(in: titles))")
    }

    func testGuideIDsAreUnique() {
        let ids = WorkflowLibrary.all.map(\.id)
        XCTAssertEqual(Set(ids).count, ids.count)
    }

    func testStepIDsAreUniqueAcrossTheCatalog() {
        let ids = WorkflowLibrary.all.flatMap { $0.steps.map(\.id) }
        XCTAssertEqual(Set(ids).count, ids.count)
    }

    func testGuideIDsAreStableAcrossLaunches() {
        // Saved progress is keyed by these IDs, so they must be derived
        // from content, never random.
        let rebuilt = Workflow(
            title: WorkflowLibrary.forgotPasswordBasics.title,
            summary: "Different summary",
            symbolName: "key",
            company: nil,
            level: .hard,
            steps: WorkflowLibrary.forgotPasswordBasics.steps
        )
        XCTAssertEqual(rebuilt.id, WorkflowLibrary.forgotPasswordBasics.id)
        XCTAssertEqual(rebuilt.steps.map(\.id), WorkflowLibrary.forgotPasswordBasics.steps.map(\.id))
    }

    func testEveryGuideHasStepsAndText() {
        for workflow in WorkflowLibrary.all {
            XCTAssertFalse(workflow.steps.isEmpty, "\(workflow.title) has no steps")
            XCTAssertFalse(workflow.summary.isEmpty, "\(workflow.title) has no summary")
            for step in workflow.steps {
                XCTAssertFalse(step.title.isEmpty, "Untitled step in \(workflow.title)")
                XCTAssertFalse(step.instruction.isEmpty, "Empty step in \(workflow.title)")
            }
        }
    }

    func testBeginnerGuidesAreInTheCatalog() {
        let all = Set(WorkflowLibrary.all.map(\.id))
        for guide in WorkflowLibrary.beginnerGuides {
            XCTAssertTrue(all.contains(guide.id), "\(guide.title) is missing from WorkflowLibrary.all")
            XCTAssertLessThanOrEqual(guide.level, .easy, "\(guide.title) should be Very Easy or Easy")
        }
    }

    // MARK: Levels

    func testEverySectionStartsWithVeryEasyGuides() {
        for group in WorkflowLibrary.grouped() {
            let name = group.company?.displayName ?? "Universal"
            XCTAssertGreaterThanOrEqual(
                group.workflows.filter { $0.level == .veryEasy }.count, 3,
                "\(name) needs at least three Very Easy guides"
            )
            XCTAssertEqual(group.workflows.first?.level, .veryEasy, "\(name) should open with a Very Easy guide")
        }
    }

    func testEveryLevelIsUsed() {
        let used = Set(WorkflowLibrary.all.map(\.level))
        XCTAssertEqual(used, Set(GuideLevel.allCases))
    }

    func testSectionsAreSortedEasiestFirst() {
        for group in WorkflowLibrary.grouped() {
            let levels = group.workflows.map(\.level)
            XCTAssertEqual(levels, levels.sorted(), "\(group.company?.displayName ?? "Universal") isn't easiest-first")
        }
    }

    func testGroupingKeepsEveryGuideExactlyOnce() {
        let grouped = WorkflowLibrary.grouped().flatMap(\.workflows).map(\.id)
        XCTAssertEqual(grouped.count, WorkflowLibrary.all.count)
        XCTAssertEqual(Set(grouped), Set(WorkflowLibrary.all.map(\.id)))
    }

    func testUniversalSectionComesFirst() {
        XCTAssertNil(WorkflowLibrary.grouped().first?.company)
    }

    func testLevelMeterMatchesRank() {
        XCTAssertEqual(GuideLevel.veryEasy.meter, "●○○○○")
        XCTAssertEqual(GuideLevel.medium.meter, "●●●○○")
        XCTAssertEqual(GuideLevel.veryHard.meter, "●●●●●")
        XCTAssertLessThan(GuideLevel.easy, GuideLevel.hard)
    }

    // MARK: Search

    func testSearchMatchesLevelNamesAndStepText() {
        let guide = WorkflowLibrary.forgotPasswordBasics
        XCTAssertTrue(WorkflowSearch.matches(guide, query: "very easy"))
        XCTAssertTrue(WorkflowSearch.matches(guide, query: "forgot password link"))
        XCTAssertTrue(WorkflowSearch.matches(guide, query: "locked out"))
        XCTAssertTrue(WorkflowSearch.matches(WorkflowLibrary.googleAccountRecovery, query: "g.co/recover"))
        XCTAssertTrue(WorkflowSearch.matches(guide, query: ""))
        XCTAssertFalse(WorkflowSearch.matches(guide, query: "kubernetes"))
    }

    // MARK: Glossary

    func testGlossaryTermsAreUnique() {
        let names = JargonGlossary.allTerms.map { $0.term.lowercased() }
        XCTAssertEqual(Set(names).count, names.count, "Duplicate terms: \(duplicates(in: names))")
    }

    func testEveryHighlightedWordHasAGlossaryCard() {
        for workflow in WorkflowLibrary.all {
            for step in workflow.steps {
                for term in step.jargonTerms {
                    XCTAssertNotNil(
                        JargonGlossary.term(named: term),
                        "\"\(term)\" in \(workflow.title) has no glossary card"
                    )
                }
            }
        }
    }

    func testBeginnerTermsLeadTheGlossary() {
        let leading = JargonGlossary.allTerms.prefix(JargonGlossary.beginnerTerms.count).map(\.id)
        XCTAssertEqual(leading, JargonGlossary.beginnerTerms.map(\.id))
    }

    // MARK: Helpers

    private func duplicates<T: Hashable>(in values: [T]) -> [T] {
        var seen = Set<T>()
        return values.filter { !seen.insert($0).inserted }
    }
}
