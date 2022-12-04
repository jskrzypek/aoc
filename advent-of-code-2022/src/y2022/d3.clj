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

(def input (get!))

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

(defn find-common
  [ruck] 
  (->> ruck
       char-array
       (split-at (/ (count ruck) 2))
       (map #(into #{} %))
       (reduce set/intersection)
  ))

(def ruck->prio
  (comp (juxt identity char->prio) first find-common))

(def sum-prios
  (transduce (map (comp second ruck->prio)) + input))

(comment
  (download-description)
  (submit-first! sum-prios)
  (->> "helloHELLO" char-array (map int))
  sum-prios
  (->> input (map ruck->prio))
  (find-common "rhPrSgfvJPfmwsTpLcsV")
  )

(comment
  (download-description)
  (submit-second!)
  )

(comment (create-next-day))

