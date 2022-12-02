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

(def
  game->play
  {"X" 0
   "Y" 3
   "Z" 6})

(defn total-score
  []
  (->> input
       (map (comp play->score #(into [] %) #(clojure.string/split % " ")))
       flatten
       (reduce +)))

(defn total-score-2
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

(comment (download-description) (submit-second!))

(comment (create-next-day))

