import XCTest
@testable import FarkleScoring

final class GameStateTests: XCTestCase {
    private func table() -> GameState {
        let game = GameState(players: [Player(name: "Mary"), Player(name: "Roger"), Player(name: "Iris")])
        game.targetScore = 2500
        return game
    }

    private func bank(_ points: Int, in game: GameState) {
        game.applyBankedScore(points, to: game.currentPlayer!.id)
        game.advanceTurn()
    }

    func testBankAndUndoRestoreScoreAndTurn() {
        let game = table()
        bank(650, in: game)
        XCTAssertEqual(game.players[0].score, 650)
        XCTAssertEqual(game.currentTurnIndex, 1)
        game.undoLastScoreEntry()
        XCTAssertEqual(game.players[0].score, 0)
        XCTAssertEqual(game.currentTurnIndex, 0)
        XCTAssertFalse(game.canUndoLastScoreEntry)
    }

    func testFarkleUndoRestoresTheBustedPlayer() {
        let game = table()
        bank(650, in: game)
        bank(0, in: game)
        XCTAssertEqual(game.currentTurnIndex, 2)
        game.undoLastScoreEntry()
        XCTAssertEqual(game.currentTurnIndex, 1)
        XCTAssertEqual(game.players[0].score, 650)
        XCTAssertEqual(game.players[1].score, 0)
    }

    func testEveryOpponentGetsAFinalTurn() {
        let game = table()
        bank(2500, in: game)
        XCTAssertTrue(game.isFinalRound)
        XCTAssertNil(game.winner)
        bank(3000, in: game)
        XCTAssertNil(game.winner)
        bank(3500, in: game)
        XCTAssertEqual(game.winner?.id, game.players[2].id)
    }

    func testUndoTargetCrossingRestoresNormalPlay() {
        let game = table()
        bank(2500, in: game)
        game.undoLastScoreEntry()
        XCTAssertFalse(game.isFinalRound)
        XCTAssertNil(game.finalRoundTriggerPlayerId)
        XCTAssertEqual(game.currentTurnIndex, 0)
        XCTAssertEqual(game.leaderScore, 0)
    }

    func testFinalFarkleFinishesGameAndCanBeUndone() {
        let game = table()
        bank(2500, in: game)
        bank(0, in: game)
        bank(0, in: game)
        XCTAssertEqual(game.winner?.id, game.players[0].id)
        game.undoLastScoreEntry()
        XCTAssertNil(game.winner)
        XCTAssertTrue(game.isFinalRound)
        XCTAssertEqual(game.currentTurnIndex, 2)
    }

    func testRematchKeepsCrewAndTargetAndClearsHistory() {
        let game = table()
        let ids = game.players.map(\.id)
        bank(2500, in: game)
        bank(0, in: game)
        bank(0, in: game)
        game.resetScores()
        XCTAssertEqual(game.players.map(\.id), ids)
        XCTAssertEqual(game.targetScore, 2500)
        XCTAssertEqual(game.players.map(\.score), [0, 0, 0])
        XCTAssertEqual(game.currentTurnIndex, 0)
        XCTAssertNil(game.winner)
        XCTAssertFalse(game.isFinalRound)
        XCTAssertFalse(game.canUndoLastScoreEntry)
    }

    func testInvalidBankDoesNotCreateUndoEntry() {
        let game = table()
        game.applyBankedScore(-50, to: game.players[0].id)
        game.applyBankedScore(100, to: UUID())
        XCTAssertEqual(game.leaderScore, 0)
        XCTAssertFalse(game.canUndoLastScoreEntry)
    }
}
