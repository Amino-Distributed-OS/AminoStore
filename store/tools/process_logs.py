import sys
import statistics as st

start, end = -1.0, -1.0

duration = float(sys.argv[2])
warmup = duration/3.0

tLatency = []
sLatency = []
fLatency = []

tRetries = []
sRetries = []
fRetries  = []

tExtra = 0.0
sExtra = 0.0
fExtra = 0.0

xLatency = []

for line in open(sys.argv[1]):
  if line.startswith('#') or line.strip() == "":
    continue

  line = line.strip().split()
  if not line[0].isdigit() or len(line) < 4:
    continue

  if start == -1:
    start = float(line[2]) + warmup
    end = start + warmup

  fts = float(line[2])

  if fts < start:
    continue

  if fts > end:
    break

  latency = int(line[3])
  status = int(line[4])
  ttype = -1
  try:
    ttype = int(line[5])
    retries = int(line[6])
  except:
    retries = 0

 # if status == 1 and ttype == 2:
 #   xLatency.append(latency)

  tLatency.append(latency)
  tRetries.append(retries)
#  tExtra += extra

  if status == 1:
    sLatency.append(latency)
    sRetries.append(retries)
#    sExtra += extra
  else:
    fLatency.append(latency)
    fRetries.append(retries)
#    fExtra += extra

if len(tLatency) == 0:
  print("Zero completed transactions..")
  sys.exit()

tLatency.sort()
sLatency.sort()
fLatency.sort()

print("Transactions(All/Success): ", len(tLatency), len(sLatency))
print("Abort Rate: ", (float)(len(tLatency)-len(sLatency))/len(tLatency))
print("Throughput (All/Success): ", len(tLatency)/(end-start), len(sLatency)/(end-start))

#print("Average Latency (all): ", sum(tLatency)/float(len(tLatency)))
print("Average Latency (all): ", st.mean(tLatency))
#print("Median  Latency (all): ", tLatency[round(len(tLatency)/2]))
print("Median  Latency (all): ", st.median(tLatency))
print("Average Number of Retries (all):", st.mean(tRetries))

#print("Average Latency (success): ", sum(sLatency)/float(len(sLatency)))
print("Average Latency (success): ", st.mean(sLatency))
#print("Median  Latency (success): ", sLatency[round(len(sLatency)/2]))
print("Median  Latency (success): ", st.median(sLatency))
print("Average Number of Retries (success):", st.mean(sRetries))

#print("Extra (all): ", tExtra)
#print("Extra (success): ", sExtra)
#if len(xLatency) > 0:
#  print("X Transaction Latency: ", sum(xLatency)/float(len(xLatency)))


if len(fLatency) > 0:
  print("Average Latency (failure): ", st.mean(fLatency))
  print("Median  Latency (failure): ", st.median(fLatency))
  print ("Average Number of Retries: (failure):", st.mean(fRetries))


#  print("Average Latency (failure): ", sum(fLatency)/float(len(tLatency)-len(sLatency)))
#  print("Extra (failure): ", fExtra)
