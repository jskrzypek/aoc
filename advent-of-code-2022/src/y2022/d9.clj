(ns
 y2022.d9
 (:require
  [aoc-util.tools
   :refer
   [create-next-day
    download-description
    download-examples
    get!
    open-browser
    submit-first!
    submit-second!]]
  [aoc-util.utils :refer [parse-int line-process] :as utils]
  [clojure.string :as str]
  [clojure.core.matrix :as mat]
  [wing.core :as w]))

(def dir->unit-vec
  "Map of parsed direction to a unit vector."
  {"U" [0 1]
   "D" [0 -1]
   "R" [1 0]
   "L" [-1 0]})

(defn instruction->H-steps
  "Convert the instruction to a lazy seq of unit vector-steps H will take."
  [[d n]]
  (repeat (Integer/parseInt n)
          (dir->unit-vec d)))

(defn parser
  ([s]
   (-> s
       (str/split #" ")
       (instruction->H-steps)))
  ([idx s]
   (-> s
       (str/split #" ")
       (instruction->H-steps)
       (conj {:idx idx :ins s}))))

(def input (->> (get!)
                (map-indexed parser)
                (apply concat)))
(def example 
  (->> (download-examples)
       (filter #(str/starts-with? % "R 4\nU"))
       first 
       (str/split-lines)
       (map-indexed parser)
       (apply concat)))

(defn HT-pos->T-step
  [H-pos T-pos]
  (let [HT-dist (mapv - H-pos T-pos)]
    ;; (prn H-pos T-pos HT-dist)
    (if (->> HT-dist
               (mapv abs)
               (apply max)
               (< 1))
      (mapv #(condp w/guard %
               (partial = 0) 0 
               (partial < 0) 1
               (partial > 0) -1)
            HT-dist)
      [0 0])))

(defn move-HT
  [H-pos T-pos H-step]
  ;; (prn H-pos T-pos H-step)
  (let [H-pos1 (mapv + H-pos H-step)
        T-step (HT-pos->T-step H-pos1 T-pos)]
    [H-pos1 H-step (mapv + T-pos T-step) T-step]))

(defn walk-HT
  [steps & {debug :debug :or {debug false}}]
  (loop [steps   steps
         H-pos   [0 0]
         T-pos   [0 0]
         time    0
         H-seen  #{[0 0]}
         T-seen  #{[0 0]}
         history [{:H H-pos :T T-pos}]]
    (if (empty? steps)
      (->> history (map :T) set)
      (if-let [{:keys [idx ins]}
               (when (-> steps first map?)
                 (first steps))]
        (do
          (printf "%04d: Instruction %02d - %s\n" (inc time) (inc idx) ins)
          (recur (rest steps) H-pos T-pos time H-seen T-seen history)) 
        (let [[H-pos1 H-step T-pos1 T-step] (move-HT H-pos T-pos (first steps))
              time          (inc time)]
          (printf
           "%04d:\n - H: %s\n - Δ: %s\n - T: %s\n"
           time
           (str "{" H-pos "+" H-step "} " :>> " " H-pos1 " (#H: " (count H-seen) ")")
           (str "{" H-pos1 "-" T-pos "} " :>> " " (mapv - H-pos1 T-pos) " | hist:" history)
           (str "{" T-pos "+" T-step "} " :>> " " T-pos1 " (#T: " (count T-seen) ")"))
          (recur (rest steps)
                 H-pos1
                 T-pos1
                 time
                 (conj H-seen H-pos1)
                 (conj T-seen T-pos1)
                 (conj history {:H H-pos1 :T T-pos1})))))))

(comment 
  input
  example
  (count (walk-HT example))
  (HT-pos->T-step [2 4] [4 3])
  
  (parser "R 4")
  (download-examples)
  (download-description)
  (walk-HT input)
  (submit-first! (walk-HT input))
  )

(comment (download-description) (submit-second!))

(comment (create-next-day))

