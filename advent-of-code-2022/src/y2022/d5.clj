(ns
 y2022.d5
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

(def input
  (let [[stacks _ instructions]
        (partition-by (partial not= "") (get!))]
    {:stacks
     (->> stacks
          (map
           #(->> %
                 (partition-all 4)
                 (map (partial filter
                               (partial not= \space)))))
          (apply mapv
                 (comp
                  (juxt (comp #(Integer/parseInt %) first) (comp vec rest))
                  (partial map (partial apply str))
                  (partial filter not-empty)
                  reverse
                  vector))
          (into {}))
     :instructions
     (->> instructions
          (map #(st/split % #"[^\d]+"))
          (map (partial filter not-empty))
          (mapv (partial map #(Integer/parseInt %))))}))



(defn execute-move
  [stacks rep from to]
  (loop [stacks stacks
         rep rep]
    (let [to- (get stacks to)
          from- (get stacks from)]
      (if (= rep 0)
        stacks
        (recur
         (assoc stacks
                from (pop from-)
                to (conj to- (peek from-)))
         (- rep 1))))))

(def final-state
  (let [{:keys [stacks instructions]} input]
    (loop [stacks stacks
           instructions instructions]
      (if-not (seq instructions)
        stacks
        (recur
         (apply execute-move stacks (first instructions))
         (rest instructions))))))

(def message
   (->> (range 1 (+ (count final-state) 1))
        (mapv (comp peek final-state))))

(comment
  input
  ((:stacks input) "5")
  pop
  (execute-move (:stacks input) 1 "5" "7")
  vec
  message
  final-state
  (download-description) 
  (submit-first! "HBTMTBSDC")
  )

(defn execute-move-2
  [stacks n from to]
  (let [to- (get stacks to)
        from- (get stacks from)
        rem (- (count from-) n)]
    (assoc stacks
           from (into [] (take rem from-))
           to (apply conj to- (drop rem from-)))))

(def final-state-2
  (let [{:keys [stacks instructions]} input]
    (loop [stacks stacks
           instructions instructions]
      (if-not (seq instructions)
        stacks
        (recur
         (apply execute-move-2 stacks (first instructions))
         (rest instructions))))))

(def message-2
  (->> (range 1 (+ (count final-state-2) 1))
       (mapv (comp peek final-state-2))))

(comment
  message-2
  (download-description)
  (submit-second! "PQTJRSHWS")
  )

(comment (create-next-day))

