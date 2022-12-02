(ns
 y2022.d2
 (:require
  [aoc-util.tools
   :refer
   [create-next-day
    download-description
    get!
    open-browser
    submit-first!
    submit-second!]]
  [aoc-util.utils :refer [parse-int line-process] :as utils]
  [clojure.edn :refer [read-string] :as edn]
  [clojure.string :as st]))

(def input (get!))


(def
  play->score
  {"A X" [3 1]
   "A Y" [6 2]
   "A Z" [0 3]
   "B X" [0 1]
   "B Y" [3 2]
   "B Z" [6 3]
   "C X" [6 1]
   "C Y" [0 2]
   "C Z" [3 3]})


(defn total-score
  []
  (->> input
       (map play->score)
       flatten
       (reduce +)))

(comment
  (download-description)
  (total-score)
  (submit-first! (total-score))
  input
  )

(def
  game->play->score
  {"X" {:score 0
        "A" 3
        "B" 1
        "C" 2}
   "Y" {:score 3
        "A" 1
        "B" 2
        "C" 3}
   "Z" {:score 6
        "A" 2
        "B" 3
        "C" 1}})
(defn parsed-game->score
  [[them outcome]]
  (let [plays (game->play->score outcome)]
    (+ (:score plays) (plays them))))

(defn game->score
  [game]
  (-> game
      (clojure.string/split #" ")
      parsed-game->score))

(defn total-score-2
  []
  (->> input
       (map game->score)
       (reduce +)))

(comment
  (download-description)
  (game->score "A X")
  (total-score-2)
  (submit-second! (total-score-2))
  )

(comment (create-next-day))

