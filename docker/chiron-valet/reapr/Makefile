BAMTOOLS_ROOT = $(CURDIR)/bamtools
CC = g++
CFLAGS = -Wl,-rpath,$(BAMTOOLS_ROOT)/lib  -Wall -O3  -I $(BAMTOOLS_ROOT)/include -L $(BAMTOOLS_ROOT)/lib
TABIX = tabix/tabix.o  -L./tabix -ltabix -lz
STATS_OBJS =  trianglePlot.o coveragePlot.o fasta.o histogram.o utils.o
SCORE_OBJS = errorWindow.o utils.o histogram.o
BREAK_OBJS = fasta.o utils.o
BAM2INSERT_OBJS = histogram.o utils.o
BAM2PERFECT_OBJS = utils.o
BAM2COV_OBJS = coveragePlot.o utils.o
BAM2FCDESTIMATE_OBJS = histogram.o utils.o trianglePlot.o
FA2GAPS_OBJS = fasta.o
SCAFF2CONTIG_OBJS = fasta.o
FA2GC_OBJS = fasta.o
GAPRESIZE_OBJS = utils.o trianglePlot.o fasta.o
FCDRATE_OBJS = histogram.o utils.o
N50_OBJS = fasta.o
EXECUTABLES = task_score task_stats task_break bam2fragCov bam2insert bam2fcdEstimate make_plots fa2gaps fa2gc scaff2contig n50 task_gapresize task_fcdrate bam2perfect

all: $(EXECUTABLES)

errorWindow.o: errorWindow.cpp
	$(CC) $(CFLAGS) -c errorWindow.cpp

trianglePlot.o: trianglePlot.cpp utils.o
	$(CC) $(CFLAGS) -c trianglePlot.cpp

coveragePlot.o: coveragePlot.cpp
	$(CC) $(CFLAGS) -c coveragePlot.cpp

fasta.o: fasta.cpp
	$(CC) $(CFLAGS) -c fasta.cpp

histogram.o: histogram.cpp
	$(CC) $(CFLAGS) -c histogram.cpp

utils.o: utils.cpp
	$(CC) $(CFLAGS) -lbamtools -c utils.cpp

task_stats: task_stats.o $(STATS_OBJS)
	$(CC) $(CFLAGS) task_stats.o $(STATS_OBJS) -lbamtools -o task_stats $(TABIX)

task_stats.o: task_stats.cpp $(STATS_OBJS)
	$(CC) $(CFLAGS) -c task_stats.cpp

task_score: task_score.o $(SCORE_OBJS)
	$(CC) $(CFLAGS) task_score.o $(SCORE_OBJS) -lbamtools -o task_score $(TABIX)

task_score.o: task_score.cpp $(SCORE_OBJS)
	$(CC) $(CFLAGS) -c task_score.cpp

task_break: task_break.o $(BREAK_OBJS)
	$(CC) $(CFLAGS) task_break.o $(BREAK_OBJS) -lbamtools -o task_break $(TABIX)

task_break.o: task_break.cpp $(BREAK_OBJS)
	$(CC) $(CFLAGS) -c task_break.cpp

bam2fragCov: bam2fragCov.o $(BAM2COV_OBJS)
	$(CC) $(CFLAGS) bam2fragCov.o $(BAM2COV_OBJS) -lbamtools -o bam2fragCov $(TABIX)

bam2fragCov.o: bam2fragCov.cpp $(BAM2COV_OBJS)
	$(CC) $(CFLAGS) -c bam2fragCov.cpp

bam2insert: bam2insert.o $(BAM2INSERT_OBJS)
	$(CC) $(CFLAGS) bam2insert.o $(BAM2INSERT_OBJS) -lbamtools -o bam2insert $(TABIX)

bam2insert.o: bam2insert.cpp $(BAM2INSERT_OBJS)
	$(CC) $(CFLAGS) -c bam2insert.cpp

bam2perfect: bam2perfect.o $(BAM2PERFECT_OBJS)
	$(CC) $(CFLAGS) bam2perfect.o $(BAM2PERFECT_OBJS) -lbamtools -o bam2perfect $(TABIX)

bam2perfect.o: bam2perfect.cpp $(BAM2PERFECT_OBJS)
	$(CC) $(CFLAGS) -c bam2perfect.cpp

bam2fcdEstimate: bam2fcdEstimate.o $(BAM2FCDESTIMATE_OBJS)
	$(CC) $(CFLAGS) bam2fcdEstimate.o $(BAM2FCDESTIMATE_OBJS) -lbamtools -o bam2fcdEstimate $(TABIX)

bam2fcdEstimate.o: bam2fcdEstimate.cpp $(BAM2FCDESTIMATE_OBJS)
	$(CC) $(CFLAGS) -c bam2fcdEstimate.cpp

make_plots: make_plots.o
	$(CC) $(CFLAGS) make_plots.o -o make_plots

make_plots.o: make_plots.cpp
	$(CC) $(CFLAGS) -c make_plots.cpp

fa2gc: fa2gc.o $(FA2GC_OBJS)
	$(CC) $(CFLAGS) fa2gc.o $(FA2GC_OBJS) -o fa2gc

fa2gc.o: fa2gc.cpp $(FA2GC_OBJS)
	$(CC) $(CFLAGS) -c fa2gc.cpp

fa2gaps: fa2gaps.o $(FA2GAPS_OBJS)
	$(CC) $(CFLAGS) fa2gaps.o $(FA2GAPS_OBJS) -o fa2gaps

fa2gaps.o: fa2gaps.cpp $(FA2GAPS_OBJS)
	$(CC) $(CFLAGS) -c fa2gaps.cpp

n50: n50.o $(N50_OBJS)
	$(CC) $(CFLAGS) n50.o $(N50_OBJS) -o n50

n50.o: n50.cpp $(N50_OBJS)
	$(CC) $(CFLAGS) -c n50.cpp

scaff2contig: scaff2contig.o $(SCAFF2CONTIG_OBJS)
	$(CC) $(CFLAGS) scaff2contig.o $(SCAFF2CONTIG_OBJS) -o scaff2contig

scaff2contig.o: scaff2contig.cpp $(SCAFF2CONTIG_OBJS)
	$(CC) $(CFLAGS) -c scaff2contig.cpp

task_gapresize: task_gapresize.o $(GAPRESIZE_OBJS)
	$(CC) $(CFLAGS) task_gapresize.o $(GAPRESIZE_OBJS) -lbamtools -o task_gapresize $(TABIX)

task_gapresize.o: task_gapresize.cpp $(GAPRESIZE_OBJS)
	$(CC) $(CFLAGS) -c task_gapresize.cpp

task_fcdrate: task_fcdrate.o $(FCDRATE_OBJS)
	$(CC) $(CFLAGS) task_fcdrate.o $(FCDRATE_OBJS) -lbamtools -o task_fcdrate $(TABIX)

task_fcdrate.o: task_fcdrate.cpp $(FCDRATE_OBJS)
	$(CC) $(CFLAGS) -c task_fcdrate.cpp

clean:
	rm -rf *.o $(EXECUTABLES)
