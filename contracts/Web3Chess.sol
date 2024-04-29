pragma solidity ^0.8.24;

contract Web3Chess {
	enum Result {
		Nothing,
		TakePiece,
		Check,
		CheckMate
	}

	enum Colour {
		None,
		White,
		Black
	}

	enum Class {
		None,
		Pawn,
		Bishop,
		Rook,
		Knight,
		Queen,
		King
	}

	enum GameState {
		None,
		Created,
		Playing,
		Ended
	}

	enum LineType {
		NotALine,
		NotClear,
		Row,
		Column,
		Diagonal
	}

	struct Position {
		uint128 x;
		uint128 y;
	}

	struct Move {
		Position from;
		Position to;
		Result result;
	}

	struct Tile {
		Colour owner;
		Class class;
	}

	struct Game {
		address player0;
		address player1;

		GameState state;

		uint8 turnNumber;

		Tile[8][8] board;
	}

	error GameExistsError();
	error InvalidPlayerError();
	error GameNotRunningError();
	error NotYourTurnError();
	error OutOfBoundsError();
	error NullMoveError();
	error InvalidMoveError();
	error InvalidMoveForPieceError();
	error CellOccupiedError(uint128 x, uint128 y);
	error NotYourPieceError(uint128 x, uint128 y);

	mapping(uint256 => Game) games;
	mapping(address => uint256) ranks;

	function createGame(
		uint256 gameId,
		address playerA,
		address playerB,
	)
		public
	{
		if (playerA == address(0))
			revert InvalidPlayerError();

		if (playerB == address(0))
			revert InvalidPlayerError();

		if (games[gameId].state != GameState.None)
			revert GameExistsError();

		bool playerAFirst = true;

		games[gameId] = Game(
			playerAFirst ? playerA : playerB,
			playerAFirst ? playerB : playerA,
			GameState.None,
			0,
			[
				[
					Tile(Colour.Black, Class.Rook),
					Tile(Colour.Black, Class.Knight),
					Tile(Colour.Black, Class.Bishop),
					Tile(Colour.Black, Class.Queen),
					Tile(Colour.Black, Class.King),
					Tile(Colour.Black, Class.Bishop),
					Tile(Colour.Black, Class.Knight),
					Tile(Colour.Black, Class.Rook)
				],
				[
					Tile(Colour.Black, Class.Pawn),
					Tile(Colour.Black, Class.Pawn),
					Tile(Colour.Black, Class.Pawn),
					Tile(Colour.Black, Class.Pawn),
					Tile(Colour.Black, Class.Pawn),
					Tile(Colour.Black, Class.Pawn),
					Tile(Colour.Black, Class.Pawn),
					Tile(Colour.Black, Class.Pawn)
				],
				[
					Tile(Colour.None, Class.None),
					Tile(Colour.None, Class.None),
					Tile(Colour.None, Class.None),
					Tile(Colour.None, Class.None),
					Tile(Colour.None, Class.None),
					Tile(Colour.None, Class.None),
					Tile(Colour.None, Class.None),
					Tile(Colour.None, Class.None)
				],
				[
					Tile(Colour.None, Class.None),
					Tile(Colour.None, Class.None),
					Tile(Colour.None, Class.None),
					Tile(Colour.None, Class.None),
					Tile(Colour.None, Class.None),
					Tile(Colour.None, Class.None),
					Tile(Colour.None, Class.None),
					Tile(Colour.None, Class.None)
				],
				[
					Tile(Colour.None, Class.None),
					Tile(Colour.None, Class.None),
					Tile(Colour.None, Class.None),
					Tile(Colour.None, Class.None),
					Tile(Colour.None, Class.None),
					Tile(Colour.None, Class.None),
					Tile(Colour.None, Class.None),
					Tile(Colour.None, Class.None)
				],
				[
					Tile(Colour.None, Class.None),
					Tile(Colour.None, Class.None),
					Tile(Colour.None, Class.None),
					Tile(Colour.None, Class.None),
					Tile(Colour.None, Class.None),
					Tile(Colour.None, Class.None),
					Tile(Colour.None, Class.None),
					Tile(Colour.None, Class.None)
				],
				[
					Tile(Colour.White, Class.Pawn),
					Tile(Colour.White, Class.Pawn),
					Tile(Colour.White, Class.Pawn),
					Tile(Colour.White, Class.Pawn),
					Tile(Colour.White, Class.Pawn),
					Tile(Colour.White, Class.Pawn),
					Tile(Colour.White, Class.Pawn),
					Tile(Colour.White, Class.Pawn)
				],
				[
					Tile(Colour.White, Class.Rook),
					Tile(Colour.White, Class.Knight),
					Tile(Colour.White, Class.Bishop),
					Tile(Colour.White, Class.Queen),
					Tile(Colour.White, Class.King),
					Tile(Colour.White, Class.Bishop),
					Tile(Colour.White, Class.Knight),
					Tile(Colour.White, Class.Rook)
				]
			]
		);
	}

	function makeMove(
		uint256 gameId,
		Position calldata from,
		Position calldata to,
		Result result
	)
		public
	{
		if (games[gameId].state != GameState.Playing)
			revert GameNotRunningError();

		uint256 playerTurn = games[gameId].turnNumber % 2;

		if (playerTurn == 0 && msg.sender != games[gameId].player0)
			revert NotYourTurnError();

		if (playerTurn == 1 && msg.sender != games[gameId].player1)
			revert NotYourTurnError();

		Colour playerColour = playerTurn == 0 ? Colour.White : Colour.Black;

		if (from.x >= 8 || from.y >= 8 || to.x >= 8 || to.y >= 8)
			revert OutOfBoundsError();

		if (to.x == from.x && to.y == from.y)
			revert NullMoveError();

		if (games[gameId].board[to.x][to.y].owner == playerColour)
			revert CellOccupiedError(from.x, from.y);

		if (games[gameId].board[from.x][from.y].owner != playerColour)
			revert NotYourPieceError(from.x, from.y);

		Class class = games[gameId].board[from.x][from.x].class;

		if (class == Class.Rook) {
			LineType lineType = isClearLine(gameId, from, to);

			if (lineType != LineType.Row && lineType != LineType.Column)
				revert InvalidMoveError();
		} else if (class == Class.Bishop) {
			LineType lineType = isClearLine(gameId, from, to);

			if (lineType != LineType.Diagonal)
				revert InvalidMoveError();
		} else if (class == Class.Queen) {
			LineType lineType = isClearLine(gameId, from, to);

			if (lineType == LineType.NotALine || lineType == LineType.NotClear)
				revert InvalidMoveError();
		} else if (class == Class.King) {
			if (!isValidKingMove(from, to))
				revert InvalidMoveError();
		} else if (class == Class.Knight) {
			if (!isValidKnightMove(from, to))
				revert InvalidMoveError();
		} else if (class == Class.Pawn) {
			if (!isValidPawnMove(gameId, playerColour, from, to))
				revert InvalidMoveError();
		}
	}

	function isValidPawnMove(
		uint256 gameId,
		Colour playerColour,
		Position calldata from,
		Position calldata to
	)
		public
		returns (bool)
	{
		uint256 distX = (from.x > to.x)
			? from.x - to.x
			: to.x - from.x;

		uint256 distY = (from.y > to.y)
			? from.y - to.y
			: to.y - from.y;

		Colour opponentColour = playerColour == Colour.White
			? Colour.Black
			: Colour.White;

		bool isAttacking = games[gameId].board[to.x][to.y].owner == opponentColour;

		uint256 homeRow = (opponentColour == Colour.White) ? 1 : 6;

		if (playerColour == Colour.White) {
			if (from.y <= to.y)
				return false;
		} else {
			if (from.y >= to.y)
				return false;
		}

		if (from.x == to.x) {
			if (isAttacking)
				return false;

			if (from.y == homeRow && distY <= 2)
				return true;

			if (distY == 1)
				return true;

			return false;
		}

		if (distX == 1 && distY == 1 && isAttacking)
			return true;

		return false;
	}

	function isValidKingMove(
		Position calldata from,
		Position calldata to
	)
		public
		returns (bool)
	{
		uint256 distX = (from.x > to.x)
			? from.x - to.x
			: to.x - from.x;

		uint256 distY = (from.y > to.y)
			? from.y - to.y
			: to.y - from.y;

		if (distX <= 1 && distY <= 1)
			return true;

		return false;
	}

	function isValidKnightMove(
		Position calldata from,
		Position calldata to
	)
		public
		returns (bool)
	{
		uint256 distX = (from.x > to.x)
			? from.x - to.x
			: to.x - from.x;

		uint256 distY = (from.y > to.y)
			? from.y - to.y
			: to.y - from.y;

		if (distX == 1 && distY == 2)
			return true;

		if (distX == 2 && distY == 1)
			return true;

		return false;
	}

	function isClearLine(
		uint256 gameId,
		Position calldata from,
		Position calldata to
	)
		public
		returns (LineType)
	{
		uint256 distX = (from.x > to.x)
			? from.x - to.x
			: to.x - from.x;

		uint256 distY = (from.y > to.y)
			? from.y - to.y
			: to.y - from.y;

		if (distY == 0) {
			uint256 startCol = (from.x > to.x)
				? to.x
				: from.x;

			uint256 row = from.y;

			for (uint256 i = 1; i < distX - 1; i++)  {
				if (games[gameId].board[row][startCol + i].owner != Colour.None)
					return LineType.NotClear;
			}

			return LineType.Row;
		}

		if (distX == 0) {
			uint256 startRow = (from.y > to.y)
				? to.y
				: from.y;

			uint256 col = from.x;

			for (uint256 i = 1; i < distY - 1; i++) {
				if (games[gameId].board[startRow + i][col].owner != Colour.None)
					return LineType.NotClear;
			}

			return LineType.Column;
		}

		if (distX == distY) {
			uint256 startCol = from.x;
			uint256 startRow = from.y;

			for (uint256 i = 1; i < distY - 1; i++) {
				uint256 row = (from.x < to.x) ? startRow + i : startRow - i;
				uint256 col = (from.y < to.y) ? startCol + i : startCol - i;

				if (games[gameId].board[row][col].owner != Colour.None)
					return LineType.NotClear;
			}

			return LineType.Diagonal;
		}

		return LineType.NotALine;
	}
}
