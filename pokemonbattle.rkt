#lang racket/base

(require db)

#|
  pokemonbattle.rkt

  Functional Pokemon battle system implemented with racket/base.
  
  
  Design principles:
  ––––––––––––––––––
  ➤ Pure functional approach
  ➤ Single battle state
  ➤ Immutable data structures
  ➤ State modifications return a new state

  Data structures:
  ––––––––––––––––
  ☐ Pokemon
  ☐ Attack
  ☐ State
  ☐ User Interface
  ☐ Testing

  Sections:
  –––––––––
  ▶ 1. Data Definitions
    ▷ 1.1 Pokemon
    ▷ 1.2 Attack
    ▷ 1.3 Battle State

  ▶ 2. API
    ▷ 2.1 Constructors
    ▷ 2.2 Getters
    ▷ 2.3 Setters
  
  ▶ 3. Database
    ▷ 3.1 Connection
    ▷ 3.2 Load Attacks
    ▷ 3.3 Load Pokemon
    ▷ 3.4 Load Pokemon Names
    ▷ 3.5 Team Creation

  ▶ 4. Enemy
    ▷ 4.1 Random Attack
    ▷ 4.2 Enemy Turn
    ▷ 4.3 Enemy Switch

  ▶ 5. Battle Logic
    ▷ 5.1 Damage Calculation
    ▷ 5.2 Attack Execution
    ▷ 5.3 Switching Pokemon
    ▷ 5.4 Game State Checks

  ▶ 6. Game Flow
    ▷ 6.1 Game Loop
      
  ▶ 7. User Interface
    ▷ 7.1 Menus
    ▷ 7.2 Input Handling
    ▷ 7.3 Game Messages

  ▶ 8. Testing
    ▷ 8.1 Test Attack Execution

  ▶ 9. Main

  
  Notes:
  ––––––
  To use the search function in Racket, press: 'Ctrl + F' ('Strg + F')


  
  ––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––
  1. Data Definitions
  ––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––   
  This section defines the data structures used in the battle system.
  

▶ 1.1 Pokemon
  –––––––––––
  Defines the Pokemon data structure represented as a vector.

  index field          description            type
  ---------------------------------------------------
    0   name           Pokemon name           String
    1   current-hp     current hit points     Integer
    2   base-hp        maximum hit points     Integer
    3   base-attack    attack stat            Integer
    4   base-defense   defense stat           Integer
    5   type           Pokemon type ('fire)   Symbol
    6   attacks        vector of attacks      Vector

  Notes:
  • current-hp is initialized with base-hp
  • Pokemon are immutable
  • HP updates create a new Pokemon using 'set-current-hp'


▶ 1.2 Attack
  ––––––––––
  Defines a battle move represented as a vector.

  index field          description            type
  ---------------------------------------------------
    0   name           attack name            String
    1   damage         base damage value      Integer
    2   type           attack type ('fire)    Symbol

  Notes:
  • Attacks are immutable
  • Attack type is used for damage calculation
  • Type effectiveness is determined by 'type-multiplier'


▶ 1.3 Battle State
  ––––––––––––––––
  Represents the complete state of the battle.

  The state stores both teams, the active Pokemon indices,
  and which player's turn it is.

  index field          description                   type
  ----------------------------------------------------------
    0   player-team    Player's team of Pokemon      List
    1   enemy-team     Enemy's team of Pokemon       List
    2   p-active       active player Pokemon index   Integer
    3   e-active       active enemy Pokemon index    Integer
    4   turn           current turn (#t player)      Boolean 
  
  Notes:
  • The state represents the entire battle
  • State updates return a new state
  • No mutation is used


  
  ––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––
  2. API
  ––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––
  The Application Programming Interface provides functions
  to access and modify the battle state.

▶ 2.1 Constructors
  ––––––––––––––––
|#

;; make-state : list list integer integer boolean -> vector
;; Returns a vector representing the complete battle state.
(define (make-state player-team enemy-team p-active e-active turn)
  (vector
   player-team
   enemy-team
   p-active
   e-active
   turn))

;; make-pokemon : string integer integer integer symbol vector -> pokemon
;; Returns a Pokemon represented as a vector.
(define (make-pokemon name base-hp base-attack base-defense type attacks)
  (vector
   name
   base-hp; current-hp
   base-hp
   base-attack
   base-defense
   type
   attacks))


#|
▶ 2.2 Getters
  –––––––––––
|#

;; get-at-index : integer list -> any
;; Returns the element at position 'index' in the given list.
(define (get-at-index index list)
  (cond ((= index 0) (car list))
        (else (get-at-index (- index 1) (cdr list)))))


;; Pokemon
(define (get-name pokemon)         (vector-ref pokemon 0))
(define (get-current-hp pokemon)   (vector-ref pokemon 1))
(define (get-base-hp pokemon)      (vector-ref pokemon 2))
(define (get-base-attack pokemon)  (vector-ref pokemon 3))
(define (get-base-defense pokemon) (vector-ref pokemon 4))
(define (get-type pokemon)         (vector-ref pokemon 5))
(define (get-attacks pokemon)      (vector-ref pokemon 6))
;; get-p-active-pokemon : state -> pokemon
;; Returns the currently active Pokemon of the player.
(define (get-p-active-pokemon state)
  (let ((team (get-player-team state))
        (index (get-p-active state)))
    (get-at-index index team)))
;; get-e-active-pokemon : state -> pokemon
;; Returns the currently active Pokemon of the enemy.
(define (get-e-active-pokemon state)
  (let ((team (get-enemy-team state))
        (index (get-e-active state)))
    (get-at-index index team)))


;; Attack
(define (get-attack-name attack)   (vector-ref attack 0))
(define (get-attack-damage attack) (vector-ref attack 1))
(define (get-attack-type attack)   (vector-ref attack 2))
;; get-attack : pokemon integer -> attack
(define (get-attack pokemon index)
  (vector-ref (get-attacks pokemon) index))


;; State
(define (get-player-team state)    (vector-ref state 0))
(define (get-enemy-team state)     (vector-ref state 1)) 
(define (get-p-active state)       (vector-ref state 2))
(define (get-e-active state)       (vector-ref state 3))
(define (get-turn state)           (vector-ref state 4))


#|
▶ 2.3 Setters
  –––––––––––
|#

;; Pokemon
;; set-current-hp : pokemon integer -> pokemon
(define (set-current-hp pokemon hp)
  (vector
   (get-name pokemon)
   (clamp-hp hp); defensive clamp
   (get-base-hp pokemon)
   (get-base-attack pokemon)
   (get-base-defense pokemon)
   (get-type pokemon)
   (get-attacks pokemon)))

;; State
;; set-player-team : state list    -> state
(define (set-player-team state team)
  (make-state team (get-enemy-team state) (get-p-active state)
              (get-e-active state) (get-turn state)))
;; set-enemy-team  : state list    -> state
(define (set-enemy-team state team)
  (make-state (get-player-team state) team (get-p-active state)
              (get-e-active state) (get-turn state)))
;; set-p-active    : state integer -> state
(define (set-p-active state index)
  (make-state (get-player-team state) (get-enemy-team state) index
              (get-e-active state) (get-turn state)))
;; set-e-active    : state integer -> state
(define (set-e-active state index)
  (make-state (get-player-team state) (get-enemy-team state)
              (get-p-active state) index (get-turn state)))
;; set-turn        : state boolean -> state 
(define (set-turn state turn)
  (make-state (get-player-team state) (get-enemy-team state)
              (get-p-active state) (get-e-active state) turn))

#|
  ––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––
  3. Database
  ––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––
  Loading data from the SQLite database.

  
  Responsibilities:
  –––––––––––––––––
  • Open a database connection
  • Load Pokemon data
  • Load attack data
  • Convert database rows into internal data structures

  Notes:
  ––––––
  • Database rows are converted into Pokemon and Attack vectors
  • Pokemon attacks are loaded via the USES relation
  • The database layer does not modify battle logic

  Tables:
  –––––––
  
  POKEMON
  –––––––
  id | name | base_hp | base_attack | base_defense | type

  
  AATTACK
  –––––––
  id | name | damage | type        

  
  USES
  ––––
  pokemon_id | attack_id
 

▶ 3.1 Connection
  ––––––––––––––
  '(require db)' provides SQLite database access.
|#

;; connect-db : -> connection
;; Opens a connection to the SQLite database file.
(define (connect-db)
  (sqlite3-connect
   #:database "pokemon.db"
   #:mode 'read-only))


#|
▶ 3.2 Load Attacks
  ––––––––––––––––
  The database query returns a list of rows.
  Each row contains the values:

  (name damage type)

  These rows are converted into Attack vectors.
|#

;; load-attacks : connection integer -> vector
(define (load-attacks conn pokemon-id)
  
  ;; Execute SQL query
  (define rows
    (query-rows; returns a list of vectors
     conn
     "SELECT a.name, a.damage, a.type
      FROM ATTACK a
      JOIN USES u ON a.id = u.attack_id
      WHERE u.pokemon_id = ?"; ? = prepared parameter = pokemon_id
     pokemon-id))

  ;; Convert rows to attack vectors
  (define (rows->attacks rows)
    (cond
      ((null? rows)
       '())
      (else
       (let* ((row (car rows))
              (name (vector-ref row 0))
              (damage (vector-ref row 1))
              (type (string->symbol (vector-ref row 2)))
              (attack
               (vector name damage type)))

         (cons attack
               (rows->attacks (cdr rows)))))))

  ;; Convert list of attacks to vector
  (list->vector (rows->attacks rows)))


#|
▶ 3.3 Load Pokemon
  ––––––––––––––––
  The database query returns a list of rows.
  Each row contains the values:

  (name base_hp base_attack base_defense type)

  These rows are converted into Pokemon vectors.
|#

;; load-pokemon : connection integer -> pokemon
(define (load-pokemon conn id)

  ;; Execute SQL query
  (define row
    (query-row; returns one vector
     conn
     "SELECT name, base_hp, base_attack, base_defense, type
      FROM POKEMON
      WHERE id = ?"; ? = id
     id))
  
  ;; Extract values from the returned row
  (define name
    (vector-ref row 0))
  (define base-hp
    (vector-ref row 1))
  (define base-attack
    (vector-ref row 2))
  (define base-defense
    (vector-ref row 3))
  (define type
    (string->symbol (vector-ref row 4)))

  ;; Load attacks assigned to this Pokemon
  (define attacks
    (load-attacks conn id))

  ;; Create Pokemon vector
  (make-pokemon
   name
   base-hp
   base-attack
   base-defense
   type
   attacks))

;; random-pokemon : connection -> pokemon
(define (random-pokemon conn)
  (load-pokemon conn (+ 1 (random 150))))


#|
▶ 3.4 Load Pokemon Names
  ––––––––––––––––––––––

  Responsibilities:
  • Query all Pokemon names
  • Return them as a list
|#

;; load-pokemon-names : connection -> list
(define (load-pokemon-names conn)

  (define rows
    (query-rows
     conn
     "SELECT name FROM POKEMON
      ORDER BY id"))

  (define (rows->names rows)
    (cond
      ((null? rows)
       '())
      (else
       (cons
        (vector-ref (car rows) 0)
        (rows->names (cdr rows))))))

  (rows->names rows))


#|
▶ 3.5 Team Creation
  –––––––––––––––––

  Responsibilities:
  –––––––––––––––––
  • Allow the player to select Pokemon by ID
  • Geńerate random teams for the enemy
|#

;; select-team : connection integer -> list
(define (select-team conn team-size)
  (display-pokemon-list conn)

  (define (build-team remaining team)
    (cond
      ((= remaining 0)
       team)
      (else
       (newline)
       (display "Choose Pokemon #: ")
       (let ((id (read-choice 1 151)))
         (let ((pokemon (load-pokemon conn id)))
           (display "Selected: ")
           (displayln (get-name pokemon))

           (build-team
            (- remaining 1)
            (cons pokemon team)))))))

  (reverse (build-team team-size '())))

;; random-team : connection integer -> list
(define (random-team conn size)

  (define (build-team remaining team)

    (cond ((= remaining 0)
           team)
          (else
           (build-team
            (- remaining 1)
            (cons (random-pokemon conn) team)))))
  (build-team size '()))


#|
  ––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––
  4. Enemy
  ––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––
  
  Responsibilities:
  –––––––––––––––––
  • Select an attack for the enemy Pokemon
  • Perform the enemy turn
  • Switch Pokemon when the active Pokemon has fainted

  Notes:
  ––––––
  • The enemy uses a simple random strategy
  • Switching occurs only if the active Pokemon has fainted


▶ 4.1 Random Attack
  –––––––––––––––––
|#

;; enemy-attack-choice : -> choice
;; Returns a random attack index.
;;
;; Attack indices:
;;   0
;;   1
;;   2
(define (enemy-attack-choice)
  (random 3))

#|
▶ 4.2 Enemy Switch
  ––––––––––––––––
|#

;; enemy-switch : state -> state
;; Switch enemy to first available Pokemon
(define (enemy-switch state)
  (let* ((team (get-enemy-team state))
         (index (first-healthy-pokemon team 0)))

    (set-e-active state index)))

#|
▶ 4.3 Enemy Turn
  ––––––––––––––
  The enemy randomly selects one of its available attacks.
  
  Responsibilities:
  • Select an attack
  • Apply the attack to the opponent
  • Update the battle state
|#

;; enemy-turn : state -> state
(define (enemy-turn state)
  (let ((attack-index (enemy-attack-choice)))
    (apply-attack state attack-index)))


#|
  ––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––
  5. Battle Logic
  ––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––
  Contains the core mechanics of the battle system.

  Responsibilities:
  –––––––––––––––––
  • Damage Calculation
  • Attack Effectiveness
  • Attack Execution
  • Pokemon Switching
  • Game State Checks

  Notes:
  • 'apply-attack' switches the turn after applying an attack


▶ 5.1 Damage Calculation
  ––––––––––––––––––––––
  The damage calculation is based on three components:

  • Base damage
    –––––––––––
    ┃ base = 5 + floor( floor((A * power) / D) / 50 )
    
    5     : Minimum damage
    A     : Attackers base attack
    power : Power of the attack
    D     : Defenders base defense
    50    : Scaling

  
  • STAB (Same Type Attack Bonus)
    –––––––––––––––––––––––––––––
    stab = 3/2 : attack type equals the attacker's Pokemon
    stab = 1   : otherwise
    

  • Type effectiveness
    ––––––––––––––––––
    eff = 0   : attack has no effect
    eff = 1/2 : attack is not very effective
    eff = 1   : normal effectiveness
    eff = 2   : super effectiveness

  
  ┃ Damage formula:
    –––––––––––––––
    damage = base * stab * eff * random


  Notes:
  ––––––
  • Rational numbers (e.g 3/2) are used instead of floating-point values.
    This keeps the damage calculation exact and avoids floating-point
    rounding errors during intermediate steps.
|#

;; clamp-hp : integer -> integer
;; Ensures that HP does not fall below zero.
(define (clamp-hp hp)
  (max 0 hp))

;; type-multiplier : symbol symbol -> rational
;; returns 0, 1/2, 1, or 2
(define (type-multiplier atk def)
  (cond
    ;; NORMAL
    ((and (eq? atk 'normal) (eq? def 'rock)) 1/2)
    ((and (eq? atk 'normal) (eq? def 'ghost)) 0)

    ;; FIRE
    ((and (eq? atk 'fire) (eq? def 'grass)) 2)
    ((and (eq? atk 'fire) (eq? def 'ice)) 2)
    ((and (eq? atk 'fire) (eq? def 'bug)) 2)
    ((and (eq? atk 'fire) (eq? def 'water)) 1/2)
    ((and (eq? atk 'fire) (eq? def 'fire)) 1/2)
    ((and (eq? atk 'fire) (eq? def 'rock)) 1/2)
    ((and (eq? atk 'fire) (eq? def 'dragon)) 1/2)

    ;; WATER
    ((and (eq? atk 'water) (eq? def 'fire)) 2)
    ((and (eq? atk 'water) (eq? def 'rock)) 2)
    ((and (eq? atk 'water) (eq? def 'ground)) 2)
    ((and (eq? atk 'water) (eq? def 'water)) 1/2)
    ((and (eq? atk 'water) (eq? def 'grass)) 1/2)
    ((and (eq? atk 'water) (eq? def 'dragon)) 1/2)

    ;; ELECTRIC
    ((and (eq? atk 'electric) (eq? def 'water)) 2)
    ((and (eq? atk 'electric) (eq? def 'flying)) 2)
    ((and (eq? atk 'electric) (eq? def 'electric)) 1/2)
    ((and (eq? atk 'electric) (eq? def 'grass)) 1/2)
    ((and (eq? atk 'electric) (eq? def 'dragon)) 1/2)
    ((and (eq? atk 'electric) (eq? def 'ground)) 0)

    ;; GRASS
    ((and (eq? atk 'grass) (eq? def 'water)) 2)
    ((and (eq? atk 'grass) (eq? def 'rock)) 2)
    ((and (eq? atk 'grass) (eq? def 'ground)) 2)
    ((and (eq? atk 'grass) (eq? def 'fire)) 1/2)
    ((and (eq? atk 'grass) (eq? def 'grass)) 1/2)
    ((and (eq? atk 'grass) (eq? def 'poison)) 1/2)
    ((and (eq? atk 'grass) (eq? def 'flying)) 1/2)
    ((and (eq? atk 'grass) (eq? def 'bug)) 1/2)
    ((and (eq? atk 'grass) (eq? def 'dragon)) 1/2)

    ;; ICE
    ((and (eq? atk 'ice) (eq? def 'grass)) 2)
    ((and (eq? atk 'ice) (eq? def 'ground)) 2)
    ((and (eq? atk 'ice) (eq? def 'flying)) 2)
    ((and (eq? atk 'ice) (eq? def 'dragon)) 2)
    ((and (eq? atk 'ice) (eq? def 'water)) 1/2)
    ((and (eq? atk 'ice) (eq? def 'ice)) 1/2)

    ;; FIGHTING
    ((and (eq? atk 'fighting) (eq? def 'normal)) 2)
    ((and (eq? atk 'fighting) (eq? def 'rock)) 2)
    ((and (eq? atk 'fighting) (eq? def 'ice)) 2)
    ((and (eq? atk 'fighting) (eq? def 'poison)) 1/2)
    ((and (eq? atk 'fighting) (eq? def 'flying)) 1/2)
    ((and (eq? atk 'fighting) (eq? def 'psychic)) 1/2)
    ((and (eq? atk 'fighting) (eq? def 'bug)) 1/2)
    ((and (eq? atk 'fighting) (eq? def 'ghost)) 0)

    ;; POISON
    ((and (eq? atk 'poison) (eq? def 'grass)) 2)
    ((and (eq? atk 'poison) (eq? def 'bug)) 2)
    ((and (eq? atk 'poison) (eq? def 'poison)) 1/2)
    ((and (eq? atk 'poison) (eq? def 'ground)) 1/2)
    ((and (eq? atk 'poison) (eq? def 'rock)) 1/2)
    ((and (eq? atk 'poison) (eq? def 'ghost)) 1/2)

    ;; GROUND
    ((and (eq? atk 'ground) (eq? def 'fire)) 2)
    ((and (eq? atk 'ground) (eq? def 'electric)) 2)
    ((and (eq? atk 'ground) (eq? def 'poison)) 2)
    ((and (eq? atk 'ground) (eq? def 'rock)) 2)
    ((and (eq? atk 'ground) (eq? def 'grass)) 1/2)
    ((and (eq? atk 'ground) (eq? def 'bug)) 1/2)
    ((and (eq? atk 'ground) (eq? def 'flying)) 0)

    ;; FLYING
    ((and (eq? atk 'flying) (eq? def 'grass)) 2)
    ((and (eq? atk 'flying) (eq? def 'fighting)) 2)
    ((and (eq? atk 'flying) (eq? def 'bug)) 2)
    ((and (eq? atk 'flying) (eq? def 'electric)) 1/2)
    ((and (eq? atk 'flying) (eq? def 'rock)) 1/2)

    ;; PSYCHIC
    ((and (eq? atk 'psychic) (eq? def 'fighting)) 2)
    ((and (eq? atk 'psychic) (eq? def 'poison)) 2)
    ((and (eq? atk 'psychic) (eq? def 'psychic)) 1/2)

    ;; BUG
    ((and (eq? atk 'bug) (eq? def 'grass)) 2)
    ((and (eq? atk 'bug) (eq? def 'psychic)) 2)
    ((and (eq? atk 'bug) (eq? def 'fire)) 1/2)
    ((and (eq? atk 'bug) (eq? def 'fighting)) 1/2)
    ((and (eq? atk 'bug) (eq? def 'flying)) 1/2)
    ((and (eq? atk 'bug) (eq? def 'ghost)) 1/2)

    ;; ROCK
    ((and (eq? atk 'rock) (eq? def 'fire)) 2)
    ((and (eq? atk 'rock) (eq? def 'ice)) 2)
    ((and (eq? atk 'rock) (eq? def 'flying)) 2)
    ((and (eq? atk 'rock) (eq? def 'bug)) 2)
    ((and (eq? atk 'rock) (eq? def 'fighting)) 1/2)
    ((and (eq? atk 'rock) (eq? def 'ground)) 1/2)

    ;; GHOST (Gen 1 Besonderheit)
    ((and (eq? atk 'ghost) (eq? def 'ghost)) 2)
    ((and (eq? atk 'ghost) (eq? def 'psychic)) 0)

    ;; DRAGON
    ((and (eq? atk 'dragon) (eq? def 'dragon)) 2)

    (else 1)))

;; attack-effectiveness : pokemon pokemon attack -> rational
;;
;; Returns:
;;   0  : no effect
;;  1/2 : not very effective
;;   1  : normal effectiveness
;;   2  : super effective
(define (attack-effectiveness attacker defender attack)
  (type-multiplier
   (get-attack-type attack)
   (get-type defender)))

;; calculate-damage : pokemon pokemon attack -> integer
;;
;; A        : base-attack
;; D        : base-defense (minimum 1 to avoid division by 0)
;; power    : power of the attack
;; atk-type : type of the attack
;; att-type : type of the attacker
;; def-type : type of the defender
;; stab     : same type attack bonus (3/2 if same type else 1)
;; eff      : effectiveness calculated based on atk-type and def-type
;; base     : base damage based on A and power
;; rand     : random number between 0.7 - 1.3
(define (calculate-damage attacker defender attack)
  (let*
      ((A (get-base-attack attacker))
       (D (max 1 (get-base-defense defender)))
       (power (get-attack-damage attack))
       (atk-type (get-attack-type attack))
       (att-type (get-type attacker))
       (def-type (get-type defender))
       (stab (cond ((equal? atk-type att-type)
                    3/2)
                    (else
                     1))); 3/2 -> no float
       (eff (attack-effectiveness attacker defender attack))
       (base (+ 5 (quotient (quotient (* A power) D) 50)))
       (rand (/ (+ 7 (random 7)) 10)))
    (floor (* base stab eff rand))))

#|
▶ 5.2 Attack Execution
  ––––––––––––––––––––
  The original team list is not modified.

  'apply-attack' creates a new defender team where the defending Pokemon
  is replaced by a new (damaged) Pokemon with updated HP.
|#

;; replace-at-index : list integer any -> list
;; Returns a new list (team) where the element at index is replaced by
;; new element (Pokemon).
(define (replace-at-index lst index new-element)
  (cond
    ((= index 0)
     (cons new-element (cdr lst)))
    (else
     (cons (car lst)
           (replace-at-index (cdr lst)
                             (- index 1)
                             new-element)))))

;; apply-attack : state integer -> state
;; integer = attack-index
;;
;; Applying damage, Updating the defender-team, Switching turn
(define (apply-attack state atk-index)
  (let* ((turn (get-turn state))
         (p-team (get-player-team state))
         (e-team (get-enemy-team state))
         (p-idx (get-p-active state))
         (e-idx (get-e-active state))
         (attacker (if turn
                       (get-p-active-pokemon state)
                       (get-e-active-pokemon state)))
         (defender (if turn
                       (get-e-active-pokemon state)
                       (get-p-active-pokemon state)))
         (attack (get-attack attacker atk-index))
         (eff (attack-effectiveness attacker defender attack))
         (damage (calculate-damage attacker defender attack))
         (new-hp (clamp-hp (- (get-current-hp defender) damage)))
         (new-defender (set-current-hp defender new-hp)))

    ;; DEBUG
    ;(display (list (get-attack-type attack) (get-type defender)))
    ;(newline)

    
    ;; UI Output
    (display-attack-result damage eff)

    (if turn    
        ;; Player attacks enemy
        (make-state
         p-team
         (replace-at-index e-team e-idx new-defender)
         p-idx
         e-idx
         #f)
        ;; Enemy attacks player
        (make-state
         (replace-at-index p-team p-idx new-defender)
         e-team
         p-idx
         e-idx
         #t))))

#|
▶ 5.3 Pokemon Switching
  –––––––––––––––––––––
  Switching updates the index of the currently active Pokemon.

  Responsibilities:
  –––––––––––––––––
  • Check if a Pokemon has fainted
  • Validate whether a switch is allowed
  • Update the active Pokemon index in the battle state

  
  Notes:
  ––––––
  • Teams are not modified during switching
  • Only the active index in the state is updated
  • Invalid indices are prevented by input validation in the UI
|#

;; first-healthy-pokemon : list integer -> integer
;; Returns index of first Pokemon with HP > 0.
(define (first-healthy-pokemon team index)
  (cond
    ((null? team)
     0)

    ((not (pokemon-fainted? (car team)))
     index)

    (else
     (first-healthy-pokemon

      (cdr team)
      (+ index 1)))))

;; pokemon-fainted? : pokemon -> boolean
;; Checks if a Pokemon is fainted
;; <= : defensive check in case clamp-hp was not applied
(define (pokemon-fainted? pokemon)
  (<= (get-current-hp pokemon) 0))

;; active-pokemon-fainted? : state -> boolean
(define (active-pokemon-fainted? state)
  (if (get-turn state)
      (pokemon-fainted? (get-p-active-pokemon state))
      (pokemon-fainted? (get-e-active-pokemon state))))

;; valid-switch? : state integer -> boolean
(define (valid-switch? state index)
  (let* ((team (get-player-team state))
         (pokemon (get-at-index index team)))
    (and
     (>= index 0)
     (not (pokemon-fainted? pokemon))
     (not (= index (get-p-active state))))))

;; switch-pokemon : state integer -> state
(define (switch-pokemon state index)
  (if (get-turn state)
      (set-p-active state index)
      (set-e-active state index)))

;; forced-player-switch : state -> state
(define (forced-player-switch state)
  (newline)
  (displayln "Your Pokemon fainted!")
  (switch-menu state)

  (let ((choice
         (read-choice 0 (- (length (get-player-team state)) 1))))

    (cond ((valid-switch? state choice)
           (set-p-active state choice))
          (else
           (forced-player-switch state)))))

;; handle-switch : state -> state
(define (handle-switch state)
  (switch-menu state)

  (let ((choice (read-choice 0 (- (length (get-player-team state)) 1))))
    (cond
      ((valid-switch? state choice)
       (set-turn
        (switch-pokemon state choice)
        #f))
      (else
       (displayln "Invalid switch.")
       state))))

#|
▶ 5.4 Game State Checks
  –––––––––––––––––––––
  These checks are used to evaluate whether Pokemon of entire teams
  are defeated and whether the battle is over.

  Responsibilities:
  –––––––––––––––––
  • Check if a Pokemon has fainted
    [5.3 'pokemon-fainted?']
  • Check if a team has no remaining active Pokemon
  • Determine if the battle is over


  Notes:
  ––––––
  • A Pokemon is considered fainted if its HP is <= 0
  • A team is defeated if all Pokemon in the team have fainted
  • The battle ends when either team is defeated
|#

;; team-defeated? : list -> boolean
;; Checks if all Pokemon fainted.
(define (team-defeated? team)
  (cond ((null? team) #t)
        ((pokemon-fainted? (car team))
         (team-defeated? (cdr team)))
        (else #f)))

;; game-over? : state -> boolean
(define (game-over? state)
  (or (team-defeated? (get-player-team state))
      (team-defeated? (get-enemy-team state))))

;; battle-result : state -> symbol
;;
;; enemy-team defeated  : 'player-win
;; player-team defeated : 'enemy-win
(define (battle-result state)
  (if (team-defeated? (get-enemy-team state))
      'player-win
      'enemy-win))


#|
  ––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––
  6. Game Flow
  ––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––

  Responsibilities:
  –––––––––––––––––
  • Executes battle turns
  • Run the main battle loop until the game ends


▶ 6.1 Game Loop
  –––––––––––––
|#

;; game-loop : state -> void
;; Runs the battle loop until the game ends.
(define (game-loop state)
  (cond

    ;; battle finished
    ((game-over? state)
     (display-end-game (battle-result state)))

    ;; player turn
    ((get-turn state)
     (battle-menu state)
    (let ((choice (read-choice 0 4)))

      (cond ((= choice 0)
             (exit-message))
            
            ;; player action
            (else
             (let* ((new-state
             (handle-battle-choice state choice))
                   (after-switch
                    (cond
                      ((and
                            (not (game-over? new-state))
                            (pokemon-fainted? (get-e-active-pokemon new-state)))
                           (enemy-switch new-state))
                      (else
                       new-state))))
               (cond
                 ((game-over? after-switch)
                  (display-end-game (battle-result after-switch)))
                 (else
                  (game-loop after-switch))))))))
      
      ;; enemy turn
      (else
       (let* ((new-state
              (enemy-turn state))
             (after-switch
              (cond
                ((and
                 (not (game-over? new-state))
                 (pokemon-fainted? (get-p-active-pokemon new-state)))
                 (forced-player-switch new-state))
                (else
                 new-state))))
         (cond
           ((game-over? after-switch)
            (display-end-game (battle-result after-switch)))
           (else
            (game-loop after-switch)))))))
        




#|
  ––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––
  7. User Interface
  ––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––
  Handles interactions with the player.

  
  Responsibilities:
  –––––––––––––––––
  • Display menus and battle information
  • Read user input
  • Validate user input
  • Control the main game loop

  
  Input rules:
  ––––––––––––
  • Only integer values are accepted as user input
  • All indices start at 0
  • Input validation is performed in the user interface


  Notes:
  ––––––
  • Battle functions assume valid input
  • Only valid indices are passed to the battle logic
  • Invalid input is rejected and requested again


▶ 7.1 Menus
  –––––––––
  These functions are responsible only for output
  and do not modify the game state.

  
  Responsibilities:
  –––––––––––––––––
  • Display the start menu
  • Display the battle status
  • Display available actions or attacks
  • Display atttack effectiveness
|#

;; start-menu : -> void
(define (start-menu)
  (displayln "Welcome to Pokemon Battle!")
  (newline)
  (displayln "[ 1 ]  Start Battle")
  (displayln "[ 0 ]  Exit"))

;; battle-mode-menu : -> void
;; Displays the battle mode selection menu.
;;
;; Modes:
;; 1 : Quick Game (random 1v1)
;; 2 : 1v1 Battle
;; 3 : 3v3 Battle
(define (battle-mode-menu)
  (newline)
  (displayln "Select Battle Mode:")
  (displayln "–––––––––––––––––––")
  (displayln "[ 1 ] Quick Game")
  (displayln "[ 2 ] 1 vs 1")
  (displayln "[ 3 ] 3 vs 3")
  (displayln "[ 0 ] Exit"))

;; display-pokemon-list : connection -> void
;; Displays all available Pokemon in a multi-column layout.
;;
;; Pokemon IDs correspond to database IDs.
;; Range: 1 - 151
(define (display-pokemon-list conn)
  (newline)
  (displayln "Available Pokemon:")
  (displayln "–––––––––––––––––––––––––––––––––––––––––––––––")

  (define names (load-pokemon-names conn))

    ;; recursive printer
    (define (print-list lst id)
      (cond
        ((null? lst)
         (newline))
        (else
         (display "#")
         (display id)
         (display " ")
         (displayln (car lst))

         (print-list
          (cdr lst)
          (+ id 1)))))
      
    (print-list names 1))

;; battle-menu : state -> void
(define (battle-menu state)
  (let* ((player (get-p-active-pokemon state))
         (enemy (get-e-active-pokemon state))
         (attacks (get-attacks player)))
    
    (newline)
    (display (get-name player))
    (display "'s HP: ")
    (display (get-current-hp player))
    (display "        ")
    
    (display (get-name enemy))
    (display "'s HP: ")
    (displayln (get-current-hp enemy))
    (newline)
    (display "[ 1 ] ")
    (displayln (get-attack-name (vector-ref attacks 0)))
    (display "[ 2 ] ")
    (displayln (get-attack-name (vector-ref attacks 1)))
    (display "[ 3 ] ")
    (displayln (get-attack-name (vector-ref attacks 2)))
    (displayln "[ 4 ] Switch Pokemon")
    
    (displayln "[ 0 ] Exit")))

;; display-team : list -> void
;; Displays all Pokemon in the player's team with their HP.
(define (display-team team)
  
  (define (print-team lst index)
    (cond
      ((null? lst)
       (newline))
      
      (else
       (let ((p (car lst)))
         (display "[ ")
         (display index)
         (display " ] ")

         (display (get-name p))

         ;; spacing
         (define name-len
           (string-length (get-name p)))

         (define spaces
           (- 12 name-len))
         (define (print-spaces n)
           (cond
             ((<= n 0) (void))
             (else
              (display " ")
              (print-spaces (- n 1)))))
         (print-spaces spaces)
         
         (display " HP: ")
         (displayln (get-current-hp p))

         (print-team (cdr lst) (+ index 1))))))
  
  (print-team team 0))

;; switch-menu : state -> void
(define (switch-menu state)
  (newline)
  (displayln "Choose Pokemon to switch:")
  (displayln "–––––––––––––––––––––––––")
  (display-team (get-player-team state)))

;; display-attack-result : integer rational -> void
;; Displays the damage dealt and an effectiveness comment.
(define (display-attack-result damage eff)
  (display damage)
  (display " damage. ")
  (display (effectiveness-message eff))

  (newline))

#|
▶ 7.2 Input Handling
  ––––––––––––––––––
  The UI accepts only integer input.
  Invalid values are rejected.


  Notes:
  ––––––
  • All indices start at 0
  • The UI ensures that only valid menu options are passed
    to the game logic
|#

;; read-choice : integer integer -> integer
;; Reads an integer between MIN and MAX from user input.
;; Repeats until a valid number is entered.
(define (read-choice min max)
  (with-handlers; catches Reader Exceptions
      ([exn:fail?
        (lambda (e)
          (display "Invalid input.") (newline)
             (display "Please enter a number between ")
             (display min) (display " and ") (display max)
             (newline)
             (read-choice min max))])
  (let ((choice (read)))
  (if (and (integer? choice)
           (<= choice max)
           (>= choice min))
      choice
      (begin (display "Invalid input.") (newline)
             (display "Please enter a number between ")
             (display min) (display " and ") (display max)
             (newline)
             (read-choice min max))))))

;; handle-battle-choice : state integer -> state
(define (handle-battle-choice state choice)
  (cond
    ((= choice 4)
     (handle-switch state))
    (else
     (apply-attack state (- choice 1)))))


#|
▶ 7.3 Game Messages
  –––––––––––––––––
  These functions only display text and do not modify the game state.
|#

;; effectiveness-message : rational -> string
;; Returns a battle message describing attack effectiveness.
(define (effectiveness-message eff)
  (cond
    ((= eff 0)   "It had no effect!")
    ((= eff 1/2) "It's not very effective...")
    ((= eff 1)   "A solid hit.")
    ((= eff 2)   "It's super effective!")
    (else "")))

;; exit-message : -> void
(define (exit-message)
  (newline)
  (display "No Pokemon were harmed during the exit.")
  (newline)
  (display "See you next time Trainer!"))

;; display-end-game : symbol -> void
(define (display-end-game result)
  (cond
    ((equal? result 'player-win)
     (displayln "Congratulations, you win!"))
    ((equal? result 'enemy-win)
     (displayln "You were defeated."))))


#|
  ––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––
  8. Testing
  ––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––
  Contains manual tests used to verify the behavior of the battle system.


▶ 8.1 Test Attack
  –––––––––––––––
|#

#|
;; Define attacks
(define thunderbolt
  (vector "thunderbolt" 90 'electric))
;; Create two Pokemon
(define pikachu
  (make-pokemon 'pikachu 35 55 40 'electric (vector thunderbolt)))
(define bulbasaur
  (make-pokemon 'bulbasur 45 49 49 'water (vector thunderbolt)))
;; Create teams
(define player-team (list pikachu))
(define enemy-team (list bulbasaur))
;; Start state
(define s0
  (make-state player-team enemy-team 0 0 #t))
;; Show result
(display "Bulbasur HP before attack: ")
(displayln (get-current-hp (get-e-active-pokemon s0)))
;; Use an attack
(define s1
  (apply-attack s0 0))
;; Show result
(display "Bulbasur HP after attack: ")
(displayln (get-current-hp (get-e-active-pokemon s1)))
|#


#|
  ––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––
  9. Main
  ––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––
  Contains the program entry point and the main battle loop.

  Responsibilities:
  –––––––––––––––––
  • Initialize the database connection
  • Load Pokemon from the database
  • Create the initial battle state
  • Start the game loop

  Notes:
  ––––––
  • The main loop runs until the battle ends or the user exits
  • State transitions are handled by the battle logic
  • The UI is responsible for user interaction
|#

;; initial-state : connection -> state
;; A random Pokemon is selected for the player and the enemy.
(define (initial-state conn)
  (let* ((player (random-pokemon conn))
         (enemy (random-pokemon conn))

         (player-team (list player))
         (enemy-team (list enemy)))

    (make-state
     player-team
     enemy-team
     0
     0
     #t)))

;; create-battle-state : connection integer -> state
;; Creates a battle state where the player selects Pokemon
;; and the enemy receives random Pokemon.
(define (create-battle-state conn team-size)
  (newline)
  (displayln "Select your Pokemon:")

  (let ((player-team (select-team conn team-size))
        (enemy-team (random-team conn team-size)))
    (make-state
     player-team
     enemy-team
     0
     0
     #t)))

;; main : -> void
;; Entry point of the program
(define (main)

  (start-menu)

  (let ((choice (read-choice 0 1)))

    (cond ((= choice 0)
           (exit-message))
          
          (else
           (battle-mode-menu)
           
           (let ((mode (read-choice 0 3)))
             
             (cond
               ((= mode 0)
                (exit-message))
               
               (else
                (let ((conn (connect-db)))
                  (cond

                    ;; Quick Game
                    ((= mode 1)
                     (game-loop
                      (initial-state conn)))

                    ;; 1v1
                    ((= mode 2)
                     (game-loop
                      (create-battle-state conn 1)))

                    ;; 3v3
                    ((= mode 3)
                     (game-loop
                      (create-battle-state conn 3))))))))))))


(main)