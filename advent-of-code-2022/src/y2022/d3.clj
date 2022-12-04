(ns
 y2022.d3
 (:require
  [aoc-util.tools
   :refer
   [create-next-day
    download-description
    get!
    submit-first!
    submit-second!]]
  [clojure.set :as set]))

(def input (map char-array (get!)))

(defn char->prio
  [^Character c]
  (let [adj (if (Character/isUpperCase c) (- (int \A) 26) (int \a))]
    (- (int c) adj -1)))
(comment
  "
   A 27
   B 28
   C 29
   D 30
   E 31
   F 32
   G 33
  "
  )

(defn ruck->compartments
  [ruck]
  (split-at (/ (count ruck) 2) ruck))

(defn find-common
  [rucks]
  (->> rucks
       (map set)
       (reduce set/intersection)
       first))


(def ruck->prio
  (comp (juxt identity char->prio) find-common))

(def sum-prios
  (transduce (map (comp second ruck->prio ruck->compartments)) + input))

(comment
  (download-description)
  (submit-first! sum-prios)
  (->> "helloHELLO" char-array (map int))
  sum-prios
  (->> input (map ruck->prio))
  (->> "rhPrSgfvJPfmwsTpLcsV"
       char-array
       ruck->compartments
       find-common)
  (ruck->compartments "rhPrSgfvJPfmwsTpLcsV") 
  )

(def sum-group-prios
  (->> input
       (partition-all 3)
       (map (comp char->prio find-common))
       (reduce +)))

(comment
  (download-description)
  sum-group-prios
  (transduce (comp find-common (take 3))
             + input)
  input
  (submit-second! sum-group-prios)
  )

(comment (create-next-day))

