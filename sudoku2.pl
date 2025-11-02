:- use_module(library(clpfd)).
:- use_module(library(random)).
:- dynamic current_grid/1.
:- dynamic hints_left/1.

% -------- Puzzle Definition(no need) --------
puzzle([
    [5,3,_,_,7,_,_,_,_],
    [6,_,_,1,9,5,_,_,_],
    [_,9,8,_,_,_,_,6,_],
    [8,_,_,_,6,_,_,_,3],
    [4,_,_,8,_,3,_,_,1],
    [7,_,_,_,2,_,_,_,6],
    [_,6,_,_,_,_,2,8,_],
    [_,_,_,4,1,9,_,_,5],
    [_,_,_,_,8,_,_,7,9]
]).

% -------- Difficulty Levels --------
difficulty(1, 50, 9). % Easy: filled, hints
difficulty(2, 40, 6). % Normal
difficulty(3, 30, 4). % Hard
difficulty(4, 20, 1). % Evil

% -------- Start Game --------
start :-
    write('Choose difficulty:'), nl,
    write('1 - Easy (50 filled, 9 hints)'), nl,
    write('2 - Normal (40 filled, 6 hints)'), nl,
    write('3 - Hard (30 filled, 4 hints)'), nl,
    write('4 - Evil (20 filled, 1 hint)'), nl,
    write('Enter your choice: '),
    read(Diff),
    difficulty(Diff, Filled, Hints),
    retractall(hints_left(_)),
    asserta(hints_left(Hints)),
    retractall(current_difficulty(_)),
    asserta(current_difficulty(Diff)),
    generate_solved_grid(Solved),
    create_puzzle(Solved, Filled, Puzzle),
    retractall(current_grid(_)),
    asserta(current_grid(Puzzle)),
    retractall(initial_grid(_)),
    asserta(initial_grid(Puzzle)),
    look.

% -------- Display Grid --------
look :-
    current_grid(Grid),
    write('    1 2 3 4 5 6 7 8 9'), nl,
    write('  +------------------+'), nl,
    print_rows_with_numbers(Grid, 1), !.

% -------- Show Initial Puzzle --------
show_initial :-
    initial_grid(Grid),
    write('Initial Puzzle:'), nl,
    write('    1 2 3 4 5 6 7 8 9'), nl,
    write('  +------------------+'), nl,
    print_rows_with_numbers(Grid, 1), !.

print_rows_with_numbers([], _).
print_rows_with_numbers([Row|Rest], RowNum) :-
    write(RowNum), write(' |'),
    maplist(print_cell, Row),
    write('|'), nl,
    NextRowNum is RowNum + 1,
    print_rows_with_numbers(Rest, NextRowNum).

print_cell(Cell) :-
    ( var(Cell) -> write(' _') ; format(' ~w', [Cell]) ).

% -------- Fill or Clear a Cell  --------
fill(Row, Col, Num) :-
    % Validate inputs
    between(1, 9, Row),
    between(1, 9, Col),
    between(0, 9, Num),  % Allow 0 for clearing
    current_grid(Grid),
    initial_grid(InitialGrid),

    % Get the initial cell and current cell
    nth1(Row, InitialGrid, InitialRow),
    nth1(Col, InitialRow, InitialCell),
    nth1(Row, Grid, CurrentRow),
    nth1(Col, CurrentRow, CurrentCell),

    ( Num = 0 ->  % Clearing the cell
        ( var(InitialCell) ->  % Only clear if it was initially blank
            % Create a new row with the cell cleared (set to a new variable)
            replace_in_row(CurrentRow, Col, _, NewRow),  % _ represents a new unbound variable
            % Create a new grid with the updated row
            replace_in_grid(Grid, Row, NewRow, NewGrid),
            retractall(current_grid(_)),
            asserta(current_grid(NewGrid)),
            write('Cell cleared successfully.'), nl,
            look  % Redisplay the grid
        ;   % If it wasn't initially blank, it's not modifiable
            write('Cannot clear this cell; it was part of the initial puzzle.'), nl
        )
    ;   % Filling the cell (Num is 1-9)
        ( var(InitialCell), var(CurrentCell) ->  % Only fill if initially blank and currently empty
            % Bind the cell to Num
            nth1(Col, CurrentRow, Cell),  % Get the cell reference
            Cell = Num,
            retractall(current_grid(_)),
            asserta(current_grid(Grid)),  % Update the grid
            write('Cell filled successfully.'), nl,
            look,  % Redisplay the grid
            % Check if puzzle is solved
            append(Grid, Vars),
            \+ (member(Var, Vars), var(Var)),  % All cells filled
            Vars ins 1..9,
            valid_rows(Grid),
            valid_columns(Grid),
            valid_blocks(Grid),
            current_difficulty(Diff),
            difficulty_score(Diff, Base),
            hints_left(H),
            UsedHints is 9 - H,
            Deduct is UsedHints * 10,
            Score is Base - Deduct,  % Using 'is' for arithmetic
            format('Puzzle completed! Score: ~w~n', [Score])
        ;   write('Cannot fill this cell; it must be initially blank and empty.'), nl
        )
    ).

% Helper predicate to replace an element in a list (for rows)
replace_in_row(Row, 1, NewValue, [NewValue|Rest]) :-
    !,
    Row = [_|Rest].  % Ensure we're working with the original row
replace_in_row([Head|Tail], Col, NewValue, [Head|NewTail]) :-
    Col > 1,
    Col1 is Col - 1,
    replace_in_row(Tail, Col1, NewValue, NewTail).

% Helper predicate to replace a row in the grid
replace_in_grid([_|RestRows], 1, NewRow, [NewRow|RestRows]).
replace_in_grid([Row|RestRows], RowNum, NewRow, [Row|NewRestRows]) :-
    RowNum > 1,
    RowNum1 is RowNum - 1,
    replace_in_grid(RestRows, RowNum1, NewRow, NewRestRows).
% -------- Check Validity --------
check :-
    current_grid(Grid),
    check_rows(Grid, RowErrors),
    check_columns(Grid, ColErrors),
    check_blocks(Grid, BlockErrors),
    ( RowErrors = [], ColErrors = [], BlockErrors = [] ->
        write('Grid is valid!'), nl
    ;   write('Grid is invalid:'), nl,
        report_errors('Row', RowErrors),
        report_errors('Column', ColErrors),
        report_errors('Block', BlockErrors)
    ).
% Returns a list of elements that appear more than once
find_duplicates(List, Dups) :-
    % Keep only numbers (ignore variables)
    include(number, List, Numbers),
    findall(X, (select(X, Numbers, Rest), member(X, Rest)), DupsUnsorted),
    sort(DupsUnsorted, Dups).

% -------- Check Rows --------
check_rows([], _, []).  % Base case: empty grid, no errors

% Case: row is correct (all elements distinct)
check_rows([Row|Rest], RowNum, Errors) :-
    all_distinct(Row),
    NextRowNum is RowNum + 1,
    check_rows(Rest, NextRowNum, Errors).

% Case: row has duplicates
check_rows([Row|Rest], RowNum, [row(RowNum, Dups)|RestErrors]) :-
    \+ all_distinct(Row),
    find_duplicates(Row, Dups),
    NextRowNum is RowNum + 1,
    check_rows(Rest, NextRowNum, RestErrors).

% Wrapper to start counting from row 1
check_rows(Grid, Errors) :-
    check_rows(Grid, 1, Errors).

% -------- Check Columns --------
check_columns([], _, []).  % Base case: no columns left

% Case: column is correct
check_columns([Col|Rest], ColNum, Errors) :-
    all_distinct(Col),
    NextColNum is ColNum + 1,
    check_columns(Rest, NextColNum, Errors).

% Case: column has duplicates
check_columns([Col|Rest], ColNum, [column(ColNum, Dups)|RestErrors]) :-
    \+ all_distinct(Col),
    find_duplicates(Col, Dups),
    NextColNum is ColNum + 1,
    check_columns(Rest, NextColNum, RestErrors).

% Wrapper to start counting from column 1
check_columns(Grid, Errors) :-
    transpose(Grid, Columns),
    check_columns(Columns, 1, Errors).

check_blocks(Grid, Errors) :-
    findall(block(BlockNum, Dups), (between(1,9,BlockNum), get_block(Grid, BlockNum, Block), \+ all_distinct(Block), find_duplicates(Block, Dups)), Errors).

get_block(Grid, BlockNum, Block) :-
    RowStart is ((BlockNum - 1) // 3) * 3 + 1,
    ColStart is ((BlockNum - 1) mod 3) * 3 + 1,
    findall(Value, (between(0,2,RI), between(0,2,CI), Row is RowStart + RI, Col is ColStart + CI, nth1(Row, Grid, R), nth1(Col, R, Value)), Block).

report_errors(_, []).
report_errors(Type, [Error|Rest]) :-
    ( Error =.. [TypeName, Num, Dups] ->
        format('~w ~w has duplicates: ~w~n', [TypeName, Num, Dups])
    ;   format('~w~n', [Error])
    ),
    report_errors(Type, Rest).

valid_rows([]).
valid_rows([Row|Rest]) :-
    all_distinct(Row),
    valid_rows(Rest).

valid_columns(Grid) :-
    transpose(Grid, Columns),
    valid_rows(Columns).

valid_blocks([]).
valid_blocks([A,B,C|Rest]) :-
    blocks(A,B,C),
    valid_blocks(Rest).

blocks([], [], []).
blocks([A,B,C|R1], [D,E,F|R2], [G,H,I|R3]) :-
    all_distinct([A,B,C,D,E,F,G,H,I]),
    blocks(R1,R2,R3).

% -------- Transpose --------
transpose([], []).
transpose([[]|_], []) :- !.
transpose(Matrix, [Row|Rows]) :-
    maplist(head, Matrix, Row),
    maplist(tail, Matrix, Rest),
    transpose(Rest, Rows).

head([H|_], H).
tail([_|T], T).

% -------- Hint System --------
hint :-
    hints_left(H),
    H > 0,
    NewH is H - 1,
    retractall(hints_left(_)),
    asserta(hints_left(NewH)),
    current_grid(Grid),
    % find first empty cell
    nth1(Row, Grid, R),
    nth1(Col, R, Cell),
    var(Cell),
    append(Grid, Vars), Vars ins 1..9,
    valid_rows(Grid),
    valid_columns(Grid),
    valid_blocks(Grid),
    % assign a valid number to this cell
    label([Cell]),
    format('row=~w, col=~w, num=~w~n', [Row, Col, Cell]),
    format('Hints remaining: ~w~n', [NewH]),
    Cell = _,   % undo assignment
    !.
hint :-
    write('No more hints available!'), nl.

% -------- Generate Solved Grid --------
generate_solved_grid(Grid) :-
    Grid = [
        [A1,A2,A3,A4,A5,A6,A7,A8,A9],
        [B1,B2,B3,B4,B5,B6,B7,B8,B9],
        [C1,C2,C3,C4,C5,C6,C7,C8,C9],
        [D1,D2,D3,D4,D5,D6,D7,D8,D9],
        [E1,E2,E3,E4,E5,E6,E7,E8,E9],
        [F1,F2,F3,F4,F5,F6,F7,F8,F9],
        [G1,G2,G3,G4,G5,G6,G7,G8,G9],
        [H1,H2,H3,H4,H5,H6,H7,H8,H9],
        [I1,I2,I3,I4,I5,I6,I7,I8,I9]
    ],
    append(Grid, Vars), Vars ins 1..9,
    valid_rows(Grid),
    valid_columns(Grid),
    valid_blocks(Grid),
    random_permutation(Vars, ShuffledVars),
    label(ShuffledVars).

% -------- Create Puzzle --------
create_puzzle(Solved, Filled, Puzzle) :-
    length(Solved, 9), % Assume 9x9
    Total = 81,
    ToRemove is Total - Filled,
    numlist(1, Total, Indices),
    random_select_indices(Indices, ToRemove, ToRemoveIndices),
    remove_by_indices(Solved, ToRemoveIndices, Puzzle).

random_select_indices(_, 0, []) :- !.
random_select_indices(List, N, [Index|Rest]) :-
    random_member(Index, List),
    select(Index, List, NewList),
    N1 is N - 1,
    random_select_indices(NewList, N1, Rest).

% -------- Remove by Indices --------
remove_by_indices(Grid, [], Grid).
remove_by_indices(Grid, [Index|Rest], NewGrid) :-
    replace_by_index(Grid, Index, TempGrid),
    remove_by_indices(TempGrid, Rest, NewGrid).

% -------- Replace by Index --------
replace_by_index(Grid, Index, NewGrid) :-
    Row is (Index - 1) // 9 + 1,
    Col is (Index - 1) mod 9 + 1,
    nth1(Row, Grid, R),
    nth1(Col, R, _),
    replace_in_row(R, Col, NewR),
    replace_in_grid(Grid, Row, NewR, NewGrid).

replace_in_row([_|Rest], 1, [_|Rest]).
replace_in_row([X|Rest], N, [X|NewRest]) :-
    N > 1,
    N1 is N - 1,
    replace_in_row(Rest, N1, NewRest).

replace_in_grid([_|Rows], 1, NewRow, [NewRow|Rows]).
replace_in_grid([Row|Rows], N, NewRow, [Row|NewRows]) :-
    N > 1,
    N1 is N - 1,
    replace_in_grid(Rows, N1, NewRow, NewRows).

% -------- Difficulty & Scoring --------
% difficulty_score(DifficultyLevel, BaseScore, MaxHints)
difficulty_score(1, 100, 9).  % Easy
difficulty_score(2, 200, 6).  % Normal
difficulty_score(3, 300, 4).  % Hard
difficulty_score(4, 500, 1).  % Evil

% -------- Check if Won --------
win :-
    current_grid(Grid),
    append(Grid, Vars),
    \+ (member(Var, Vars), var(Var)),  % all cells filled
    Vars ins 1..9,
    valid_rows(Grid),
    valid_columns(Grid),
    valid_blocks(Grid),
    current_difficulty(Diff),
    difficulty_score(Diff, Base, MaxHints),
    hints_left(H),
    UsedHints is MaxHints - H,
    Score is Base - (UsedHints * 10),
    format('Congratulations! You solved the puzzle. Score: ~w~n', [Score]).

% -------- Solve Sudoku --------
solve :-
    current_grid(Grid),
    append(Grid, Vars), Vars ins 1..9,
    valid_rows(Grid),
    valid_columns(Grid),
    valid_blocks(Grid),
    label(Vars),
    retractall(current_grid(_)),
    asserta(current_grid(Grid)),
    look.
