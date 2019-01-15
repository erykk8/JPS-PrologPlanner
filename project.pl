plan_wrapper(InitState, Goals, MaxLimit, Plan, FinalState) :-
	consult('helpers.pl'),
	is_between(0, MaxLimit, Limit),
	write("Trying Limit: "),
	write_ln(Limit),
	plan(InitState, Goals, [], Limit, Plan, FinalState, 0).

plan(State, Goals, _, _, [], State, RecursionLevel) :-
	write("Recursion level is: "),
	write_ln(RecursionLevel),
	goals_achieved(Goals, State),
	write_ln("Achieved goal").
	% write("Goals: "),
	% write(Goals),
	% write_ln(" achieved!").

plan(InitState, Goals, AchievedGoals, Limit, Plan, FinalState, RecursionLevel) :-
	Limit > 0,
	write("Recursion: "),
	write_ln(RecursionLevel),
	write("Goals: "),
	write_ln(Goals),
	write("AchievedGoals: "),
	write_ln(AchievedGoals),
	% wygeneruje LimitPre od 0 do Limit
	is_between(0, Limit-1, LimitPre),
	write("Trying LimitPre: "),
	write_ln(LimitPre),
	choose_goal(Goal, Goals, RestGoals, InitState), % pkt wyboru - kolejnosc goali moze miec znaczenie
	achieves(Goal, Action),
	write("Chosen goal needs action: "),
	write_ln(Action),
	requires(Action, CondGoals, Conditions),
	write("Action needs goals: "),
	write(CondGoals),
	write(" and conditions: "),
	write_ln(Conditions),
	Rec2 is RecursionLevel + 1,
	write_ln("Making PrePlan to reach action goals..."),
	plan(InitState, CondGoals, AchievedGoals, LimitPre, PrePlan, State1, Rec2),
	write("PrePlan: "),
	write_ln(PrePlan),
	write("State1: "),
	write_ln(State1),
	inst_action(Action, Conditions, State1, InstAction), % pkt wyboru ponownie (miejsca do odstawienia)
	check_action(InstAction, AchievedGoals),
	perform_action(State1, InstAction, State2),
	write("State2: "),
	write_ln(State2),
	% reszta idzie do LimitPost
	LimitPost is Limit - LimitPre - 1,
	write("LimitPost is: "),
	write_ln(LimitPost),
	plan(State2, RestGoals, [Goal | AchievedGoals], LimitPost, PostPlan, FinalState, Rec2),
	conc(PrePlan, [InstAction | PostPlan ], Plan).
	
plan(_, _, _, _, _, _) :-
	write_ln("Failed to find plan within limit"),
	fail.

goals_achieved([], _).

goals_achieved([HeadGoal | Rest], UnitedState) :-
	%% member(HeadGoal, UnitedState), %% ! struktura /
	goal_achieved(HeadGoal, UnitedState),
	goals_achieved(Rest, UnitedState).

goal_achieved(A, _) :-
	write("Checking if goal achieved: "),
	write_ln(A),
	fail.
	
goal_achieved(on(A, B), UnitedState) :-
	non_slash(A),
	non_slash(B),
	member(on(A, B), UnitedState).

goal_achieved(clear(A), State) :-
	non_slash(A),
	member(clear(A), State).
	
goal_achieved(clear(A/Goal), State) :-
	% goal_achieved(clear(X), [...])
	
	nonvar(Goal),
	goal_achieved(Goal, State),
	member(clear(A), State).

goal_achieved(on(A, B/Goal2), UnitedState) :-
	non_slash(A),
	nonvar(Goal2),
	goal_achieved(Goal2, UnitedState),
	member(on(A, B), UnitedState).

% generalization only
goal_achieved(on(A/Goal, B), UnitedState) :- 
	nonvar(Goal),
	goal_achieved(Goal, UnitedState),
	member(on(A, B), UnitedState).
	
goal_achieved(on(A/Goal, B/Goal2), UnitedState) :-
	nonvar(Goal),
	nonvar(Goal2),
	goal_achieved(Goal, UnitedState),
	goal_achieved(Goal2, UnitedState),
	member(on(A, B), UnitedState).
	

choose_goal(Goal, [Goal | Goals], Goals, UnitedState) :-
	% member(Goal, [Goal | Goals]),
	not(goal_achieved(Goal, UnitedState)).
	
choose_goal(Goal, [X | Goals], [X | TailRestGoals], UnitedState) :-
	choose_goal(Goal, Goals, TailRestGoals, UnitedState).
	
achieves(on(A, B), move(A, Y/(on(A, Y)), B)).

achieves(clear(B), move(A/on(A,B), B, C)).

%% requires(Action, CondGoals, Conditions) :-CELE

requires(move(What, From, On), [clear(What), clear(On)], [on(What, From)]) :-
	non_slash(From),
	nonvar(What),
	nonvar(On).
	
requires(move(What, From/on(What, From), On), [clear(What), clear(On)], [on(What, From)]) :-
	nonvar(What),
	nonvar(On).

requires(move(What, From, On), [clear(What)], [clear(On), safe_diff(On, What)]) :-
	var(On).

% check_action(InstAction, AchievedGoals)
check_action(_, []).

check_action(InstAction, [Goal|Rest]) :-
	not(action_destroys_goal(InstAction, Goal)),
	check_action(InstAction, Rest).

action_destroys_goal(move(What, From, _), on(What, From)).

action_destroys_goal(move(_, _, On), clear(On)).


% inst_action(Action, Conditions, State1, InstAction)
inst_action(A, CONDS, STATE, _) :-
	write("inst_action: ACTION: "),
	write(A),
	write(" CONDS: "),
	write(CONDS),
	write(" STATE: "),
	write_ln(STATE),
	fail.

inst_action(move(What, From, On), Conds, UnitedState, move(InstWhat, InstFrom, InstOn)) :-
	write_ln("Inst action:"),
	write_ln(What),
	write_ln(From),
	write_ln(On),
	inst_one(What, UnitedState, InstWhat),
	inst_one(From, UnitedState, InstFrom),
	inst_one(On, UnitedState, InstOn),
	conds_achieved(Conds, UnitedState),
	write("Achieved conditions: "),
	write_ln(Conds).

conds_achieved([], _).

conds_achieved([safe_diff(A, B) | Rest], UnitedState) :-
    non_slash(A),
    non_slash(B),
    conds_achieved(Rest, UnitedState), !,
	safe_diff(A, B).
	
conds_achieved([safe_diff(A, B/W) | Rest], UnitedState) :-
    non_slash(A),
	goal_achieved(W, UnitedState),
	conds_achieved(Rest, UnitedState), !,
	safe_diff(A, B).

conds_achieved([safe_diff(A/W, B) | Rest], UnitedState) :-
    non_slash(B),
	goal_achieved(W, UnitedState),
	conds_achieved(Rest, UnitedState), !,
	safe_diff(A, B).

conds_achieved([safe_diff(A/W, B/W2) | Rest], UnitedState) :-
	goal_achieved(W, UnitedState),
	goal_achieved(W2, UnitedState),
	conds_achieved(Rest, UnitedState), !,
	safe_diff(A, B).

conds_achieved([HeadGoal | Rest], UnitedState) :-
	HeadGoal \= safe_diff(_, _),
	goal_achieved(HeadGoal, UnitedState),
	conds_achieved(Rest, UnitedState).

conds_achieved(D, _) :-
	write("Failed to achieve conditions: "),
	write_ln(D),
	fail.

%inst_one(A, UnitedState, UserInput) :-
    %var(A),
    %write_ln(UnitedState),
    %write("Wybierz wartosc dla "),
    %write(A),
    %write_ln(":"),
    %read(UserInput),
    %UserInput \= "cofnij", !.
	
inst_one(A, UnitedState, A) :-
	non_slash(A).
	
inst_one(A/B, UnitedState, A) :-
    % zeby nie generowac nowych zmiennych postaci Zmienna/Zmienna2 po nawrocie
    var(A),
    var(B), !,
	fail.
	
inst_one(A/B, UnitedState, A) :-
	goal_achieved(B, UnitedState).

perform_action(State1, move(What, From, On), [on(What, On), clear(From) | PartialRes]) :-
    delete(clear(On), State1, PartialPartialRes),
    delete(on(What, From), PartialPartialRes, PartialRes).

