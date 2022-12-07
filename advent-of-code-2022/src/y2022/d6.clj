(ns
 y2022.d6
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

(def input (first (get!)))

(defn find-start
  [s n]
  (let [max-ct (count s)]
    (loop [ct 0
           s s
           mem ""]
    ;; (prn ct (apply str (take 10 s)) mem)
      (if (or (> ct max-ct) (= n (-> mem st/trim count)))
        ct
        (recur (inc ct)
               (apply str (drop 1 s))
               (str
                " "
                (->> s
                     first
                     str
                     re-pattern
                     (st/split mem)
                     last
                     st/trim
                     (take-last (- n 1))
                     (apply str))
                (first s)
                " "))))))

(comment
  (find-start input 14)
  input
  (download-description)
  (submit-first! 1779)
  )

(defn find-start-2
  ([s range] (find-start-2 s range 0))
  ([s range ct]
   (if (->> s (take range) set count (= range))
     (+ ct range)
     (find-start-2 (rest s) range (inc ct)))))

(comment
  (find-start-2 input 14)
  (find-start-2 "mjqjpqmgbljsphdztnvjfqwrcgsmlb" 14)
  
  (download-description)
  (submit-second! 2635)
  )

(comment
  (create-next-day)
  )

