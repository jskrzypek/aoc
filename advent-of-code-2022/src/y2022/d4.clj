(ns
 y2022.d4
 (:require
  [aoc-util.tools
   :refer
   [create-next-day
    download-description
    get!
    submit-first!
    submit-second!]]
  [aoc-util.utils :refer [parse-int line-process] :as utils]
  [clojure.edn :refer [read-string] :as edn]
  [clojure.string :as st]))

(defn ->asst-pair
  [l]
  (->> (st/split l #"[-,]")
       (map #(Integer/parseInt %))
       (partition 2)))

(def input
  (map ->asst-pair
       (get!)))

(defn ⊇?
  [[[min1 max1] [min2 max2]]]
  (when (and (<= min1 min2) (>= max1 max2))
    true))

(defn ⊆?
  [[[min1 max1] [min2 max2]]]
  (when (and (<= min2 min1) (>= max2 max1))
    true))

(def num-contains
  (->> input
      (filter (some-fn ⊇? ⊆?))
      count))
(comment
  input
  (count input)
  (filter (some-fn ⊇? ⊆?) input)
  num-contains
  (download-description)
  (submit-first! num-contains)
  )

(defn loverlap?
  [[[min1 max1] [_ max2]]]
  (when (and (<= min1 max2) (>= max1 max2))
    true))

(defn roverlap?
  [[[_ max1] [min2 max2]]]
  (when (and (<= min2 max1) (>= max2 max1))
    true))

(def num-overlaps
  (->> input
      (filter (some-fn loverlap? roverlap?))
      count))

(comment
  num-overlaps
  (filter (some-fn loverlap? roverlap?) input)
  (roverlap? '((3 11) (12 12)))
  (download-description)
  (submit-second! num-overlaps)
  )

(comment (create-next-day))

