(ns
 y2022.d8
  (:require
   [aoc-util.tools
    :refer
    [create-next-day
     download-description
     download-examples
     get!
     parse-input
     open-browser
     submit-first!
     submit-second!]]
   [aoc-util.utils :refer [parse-int line-process] :as utils]
   [clojure.string :as str]
   [clojure.core.matrix :as mat]))

(mat/set-current-implementation :ndarray)

(defn line-parser
  [s]
  (->> s
       char-array
       (mapv (comp #(Integer/parseInt %) str))))
(comment
  (line-parser  "45"))
(def input 
  (mat/matrix :ndarray
          (get! line-parser)))
(def example
  (mat/matrix
   :ndarray
   (-> (download-examples)
       first
       (parse-input line-parser)
       )))

(defn split-slice
  [m a b get-slice]
  (->> a
       (get-slice m)
       ((juxt (partial take b) (partial drop (inc b))))))


(defn is-vis?
  ([m] (partial is-vis? m))
  ([m index]
   (is-vis? m index (apply  m index)))
  ([m [y x] v & {debug :debug}]
   (let [[nr nc] (mat/shape m)
         vis-dir          
         (cond
           (= 0 y)        {:name :up    :edge true :vis true}
           (= x (dec nc)) {:name :right :edge true :vis true}
           (= y (dec nr)) {:name :down  :edge true :vis true}
           (= 0 x)        {:name :left  :edge true :vis true}
           :else
           (let
            [[up down]    (split-slice m x y mat/get-column)
             [left right] (split-slice m y x mat/get-row)]
             (->> [[y        {:name :up    :dir up}]
                   [(- nr y) {:name :down  :dir down}]
                   [x        {:name :left  :dir left}]
                   [(- nc x) {:name :right :dir right}]]
                  (sort-by first)
                  (map second)
                  (some
                   (fn [{:keys [dir] :as opdir}]
                     (if (> v (apply max dir))
                       (assoc opdir :vis true )
                       (when debug
                         (prn "!" [y x] v (assoc opdir
                                                 :vis false
                                                 :max (apply max dir))))))))))]
     (when debug (prn "+" [y x] v vis-dir))
     (:vis vis-dir))))

(defn mvis
  ([m] (mvis m 1 0))
  ([m f] (mvis m 1 f))
  ([m t f & {:as opts :or {}}]
   (mat/emap-indexed #(if (is-vis? m %1 %2 opts) t f) m)))
(defn pvis
  [m & {:as opts :or {}}]
  (-> m
      (mvis 1 -1 opts)
      (mat/e* m)
      mat/pm))

(comment
  (not-empty "3")
  input
  example
  (mat/shape example)
  (is-vis? example [2 2] 3 {:debug true})
  (->> example
       (eduction))
  (->> [1 2 3 4 5 3 2]
       ((fn [v]))
       #_(reduce #(when (< %1 %2) %2)))
  (download-description)
  (mat/emap-indexed #(if (is-vis? example %1 %2) 1 0) example)
  (mat/esum (mat/emap-indexed #(if (is-vis? example %1 %2 {:debug true}) 1 0) example))
  (count (filter (is-vis? example) (mat/index-seq example)))
  (count (filter (is-vis? input) (mat/index-seq input)))
  (mat/pm (mvis example 1 0 {:debug true}))
  (pvis example {:debug true})
  (mat/non-zero-count (mvis input))
  (submit-first!
   (mat/non-zero-count (mvis input)))
  )

(defn scenic-score-slice
  ([v] (partial scenic-score-slice v))
  ([v sl & printme]
   (max
    ;; (if (seq sl) 1 0)
    1
    (->> sl
         (reduce
          (fn [a n]
            (if (and
                 (>= v (or (last a) 0))
                 (>= n (or (last a) 0)))
              (conj a n)
              a))
          [])
         count))))

(defn scenic-score
  ([m] (partial scenic-score m))
  ([m index]
   (scenic-score m index (apply mat/mget m index)))
  ([m [y x] v]
   (let
    [[up down]    (split-slice m x y mat/get-column)
     [left right] (split-slice m y x mat/get-row)]
     (->> (mapv (juxt (comp identity first) (comp vec second)) [[:up up] [:right right]])
          (concat
           (mapv (juxt (comp identity first) (comp vec reverse vec second)) [[:down down] [:left left]]))
          (mapv (juxt identity (comp #(scenic-score-slice v % [y x]) second)))
          (map (fn [[[name sl] sc]] sc))
          (reduce *)))))

(comment
  (scenic-score example [1 2])
  (mat/index-seq example)
  (mat/pm 
   (mat/emap-indexed (scenic-score example) example))
  (mat/emax (mat/emap-indexed (scenic-score example) example))
  (download-description)
  (mat/emax (mat/emap-indexed (scenic-score input) input))
  (submit-second! (mat/emax (mat/emap-indexed (scenic-score input) input)))
  )

(comment
  (create-next-day))

