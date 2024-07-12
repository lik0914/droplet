/*
 * Copyright (c) Huawei Technologies Co., Ltd. 2023-2024. All rights resvered.
 */

package glide

/*	/*
 * NeuQuant Neural-Net Quantization Algorithm
 * ------------------------------------------
 *
 * Copyright (c) 1994 Anthony Dekker
 *
 * NEUQUANT Neural-Net quantization algorithm by Anthony Dekker, 1994. See
 * "Kohonen neural networks for optimal colour quantization" in "Network:
 * Computation in Neural Systems" Vol. 5 (1994) pp 351-367. for a discussion of	 * Copyright (c) Huawei Technologies Co., Ltd. 2023-2024. All rights resvered.
 * the algorithm.
 *
 * Any party obtaining a copy of these files from the author, directly or
 * indirectly, is granted, free of charge, a full and unrestricted irrevocable,
 * world-wide, paid up, royalty-free, nonexclusive right and license to deal in
 * this software and documentation files (the "Software"), including without
 * limitation the rights to use, copy, modify, merge, publish, distribute,
 * sublicense, and/or sell copies of the Software, and to permit persons who
 * receive copies from any such party to do so, with the only requirement being
 * that this copyright notice remain intact.
 */	 */


// Ported to Java 12/00 K Weiner

class NeuQuant {

    protected let netsize:Int32 = 256; /* number of colours used */

    /* four primes near 500 - assume no image has a length so large */
  /* that it is divisible by all four primes */
    protected let prime1:Int32 = 499;

    protected let prime2:Int32 = 491;

    protected let prime3:Int32 = 487;

    protected let prime4:Int32 = 503;

    protected let minpicturebytes:Int32 = (3 * prime4);

  /* minimum size for input image */

  /*
   * Program Skeleton ---------------- [select samplefac in range 1..30] [read
   * image from input file] pic = (unsigned char*) malloc(3*width*height);
   * initnet(pic,3*width*height,samplefac); learn(); unbiasnet(); [write output
   * image header, using writecolourmap(f)] inxbuild(); write output image using
   * inxsearch(b,g,r)
   */

  /*
   * Network Definitions -------------------
   */

    protected let maxnetpos:Int32 = (netsize - 1);

    protected let netbiasshift:Int32 = 4; /* bias for colour values */

    protected let ncycles:Int32 = 100; /* no. of learning cycles */

    /* defs for freq and bias */
    protected let intbiasshift:Int32 = 16; /* bias for fractions */

    protected let intbias:Int32 = ((Int32(1)) << intbiasshift);

    protected let gammashift:Int32 = 10; /* gamma = 1024 */

    protected let gamma:Int32 = ((Int32(1)) << gammashift);

    protected let betashift:Int32 = 10;

    protected let beta:Int32 = (intbias >> betashift); /* beta = 1/1024 */

    protected let betagamma:Int32 = (intbias << (gammashift - betashift));

    /* defs for decreasing radius factor */
    protected let initrad:Int32 = (netsize >> 3); /*
                                                         * for 256 cols, radius
                                                         * starts
                                                         */

    protected let radiusbiasshift:Int32 = 6; /* at 32.0 biased by 6 bits */

    protected let radiusbias:Int32 = ((Int32(1)) << radiusbiasshift);

    protected let initradius:Int32 = (initrad * radiusbias); /*
                                                                   * and
                                                                   * decreases
                                                                   * by a
                                                                   */

    protected let radiusdec:Int32 = 30; /* factor of 1/30 each cycle */

    /* defs for decreasing alpha factor */
    protected let alphabiasshift:Int32 = 10; /* alpha starts at 1.0 */

    protected let initalpha:Int32 = ((Int32(1)) << alphabiasshift);

    protected var alphadec:Int32 = 0; /* biased by 10 bits */

    /* radbias and alpharadbias used for radpower calculation */
    protected let radbiasshift:Int32 = 8;

    protected let radbias:Int32 = ((Int32(1)) << radbiasshift);

    protected let alpharadbshift:Int32 = (alphabiasshift + radbiasshift);

    protected let alpharadbias:Int32 = ((Int32(1)) << alpharadbshift);

  /*
   * Types and Global Variables --------------------------
   */

    protected var thepicture:Array<UInt8>; /* the input image itself */

    protected var lengthcount:Int32; /* lengthcount = H*W*3 */

    protected var samplefac:Int32; /* sampling factor 1..30 */

    // typedef int pixel[4]; /* BGRc */
    protected var network:Array<Array<Int32>>; /* the network itself - [netsize][4] */

    protected var netindex:Array<Int32> = Array<Int32>(256,item:0);

  /* for network lookup - really 256 */

    protected var bias:Array<Int32> = Array<Int32>(Int64(netsize),item:0)

    /* bias and freq arrays for learning */
    protected var freq:Array<Int32> = Array<Int32>(Int64(netsize),item:0)

    protected var radpower:Array<Int32> = Array<Int32>(Int64(initrad),item:0)

  /* radpower for precomputation */

    /*
     * Initialise network in range (0,0,0) to (255,255,255) and set parameters
     * -----------------------------------------------------------------------
     */
    public init(thepic:Array<UInt8>, len:Int32, sample:Int32) {

        var i:Int32;
        var p:Array<Int32>;

        thepicture = thepic;
        lengthcount = len;
        samplefac = sample;

        network = Array<Array<Int32>>(Int64(netsize),item:Array<Int32>())   //可能不对。
        for (i in 0..Int64(netsize)) {
            network[i] = Array<Int32>(4, item:0)
            p = network[i];
            p[2] = (Int32(i) << (netbiasshift + 8)) / netsize;
            p[1] = p[2]
            p[0] = p[1]
            freq[i] = intbias / netsize; /* 1/netsize */
            bias[i] = 0;
        }
    }

    public func colorMap():Array<UInt8> {
        var map:Array<UInt8> = Array<UInt8>(Int64(3 * netsize),item:0)
        var index:Array<Int32> = Array<Int32>(Int64(netsize),item:0)
        for ( i in 0..netsize){
            index[Int64(network[Int64(i)][3])] = i;
        }
        var k = 0;
        for ( i in 0..Int64(netsize)) {
            var j = Int64(index[i])
            map[k] = UInt8(network[j][0]);
            k++
            map[k] = UInt8(network[j][1]);
            k++
            map[k] = UInt8(network[j][2]);
            k++
        }
        return map;
    }

    /*
     * Insertion sort of network and building of netindex[0..255] (to do after
     * unbias)
     * -------------------------------------------------------------------------------
     */
    public func inxbuild() {

        var j:Int32; var smallpos:Int32; var smallval:Int32; var previouscol:Int32; var startpos:Int32
        var p:Array<Int32>; var q:Array<Int32>;

        previouscol = 0;
        startpos = 0;
        for (i in 0..netsize) {
            p = network[Int64(i)];
            smallpos = i;
            smallval = p[1]; /* index on g */
      /* find smallest in i..netsize-1 */
            for (j1 in i + 1..netsize) {
                j = j1
                q = network[Int64(j1)];
                if (q[1] < smallval) { /* index on g */
                    smallpos = j1;
                    smallval = q[1]; /* index on g */
                }
            }
            q = network[Int64(smallpos)];
      /* swap p (i) and q (smallpos) entries */
            if (i != smallpos) {
                j = q[0];
                q[0] = p[0];
                p[0] = j;
                j = q[1];
                q[1] = p[1];
                p[1] = j;
                j = q[2];
                q[2] = p[2];
                p[2] = j;
                j = q[3];
                q[3] = p[3];
                p[3] = j;
            }
      /* smallval entry is now in position i */
            if (smallval != previouscol) {
                netindex[Int64(previouscol)] = (startpos + i) >> 1;
                for (j1 in previouscol + 1..smallval)
                {
                    j=j1
                    netindex[Int64(j1)] = i;
                }
                previouscol = smallval;
                startpos = i;
            }
        }
        netindex[Int64(previouscol)] = (startpos + maxnetpos) >> 1;
        for (j in previouscol + 1..256){
            netindex[Int64(j)] = maxnetpos; /* really 256 */
        }
    }

    /*
     * Main Learning Loop ------------------
     */
    public func learn():Unit {

        var i:Int32
        var j:Int32
        var b:Int32
        var g:Int32
        var r:Int32
        
        var radiuscj:Int32
        var radcj:Int32
        var alpha:Int32
        var step:Int64
        var delta:Int32
        var samplepixelscj:Int32

        var p:Array<UInt8>;
        var pix:Int64
        var lim:Int64
        
        let lengthcount64 = Int64(lengthcount)
        

        if (lengthcount < minpicturebytes){
            samplefac = 1;
        }
        alphadec = 30 + ((samplefac - 1) / 3);
        p = thepicture;
        pix = 0;
        lim = lengthcount64;
        samplepixelscj = lengthcount / (3 * samplefac);
        delta = samplepixelscj / ncycles;
        alpha = initalpha;
        radiuscj = initradius;

        radcj = radiuscj >> radiusbiasshift;
        if (radcj <= 1){
            radcj = 0;
        }

        for (i in 0..radcj){
            radpower[Int64(i)] = alpha * (((radcj * radcj - i * i) * radbias) / (radcj * radcj));
        }

        // fprintf(stderr,"beginning 1D learning: initial radius=%d\n", rad);

        let prime164 = Int64(prime1)
        let prime264 = Int64(prime2)
        let prime364 = Int64(prime3)
        let prime464 = Int64(prime4)

        if (lengthcount < minpicturebytes){
            step = 3;
        } else if ((lengthcount % prime1) != 0){
            step = 3 * prime164;
        } else {
            if ((lengthcount % prime2) != 0){
                step = 3 * prime264;
            } else {
                if ((lengthcount % prime3) != 0){
                    step = 3 * prime364;
                } else{
                    step = 3 * prime464;
                }
            }
        }
//  let now = Time.now()
        i = 0;
        
        while (i < samplepixelscj) {
            b = Int32(p[pix + 0] & 0xff) << netbiasshift;
            g = Int32(p[pix + 1] & 0xff) << netbiasshift;
            r = Int32(p[pix + 2] & 0xff) << netbiasshift;
            j = contest(b, g, r);

            altersingle(alpha, j, b, g, r);
            if (radcj != 0){
                alterneigh(radcj, j, b, g, r); /* alter neighbours */
            }

            pix += step;
            if (pix >= lim){
                pix -= lengthcount64;
            }

            i++;
            if (delta == 0){
                delta = 1;
            }

            if (i % delta == 0) {
                alpha -= alpha / alphadec;
                radiuscj -= radiuscj / radiusdec;
                radcj = radiuscj >> radiusbiasshift;
                if (radcj <= 1){
                    radcj = 0;
                }
                for (j in 0..radcj){
                    radpower[Int64(j)] = alpha * (((radcj * radcj - j * j) * radbias) / (radcj * radcj));
                }
            }

        }
// AppLog.error("time: ${Time.since(now)}")
        // fprintf(stderr,"finished 1D learning: final alpha=%f
        // !\n",((float)alpha)/initalpha);
    }

    /*
     * Search for BGR values 0..255 (after net is unbiased) and return colour
     * index
     * ----------------------------------------------------------------------------
     */
    public func map(b:Int32, g:Int32, r:Int32):Int32 {

        var i:Int32
        var j:Int32
        var distcj:Int32
        var a:Int32
        var bestd:Int32
        
        var p:Array<Int32>;
        var best:Int32;

        bestd = 1000; /* biggest possible dist is 256*3 */
        best = -1;
        i = netindex[Int64(g)]; /* index on g */
        j = i - 1; /* start at netindex[g] and work outwards */

        while ((i < netsize) || (j >= 0)) {
            if (i < netsize) {
                p = network[Int64(i)];
                distcj = p[1] - g; /* inx key */
                if (distcj >= bestd){
                    i = netsize; /* stop iter */
                } else {
                    i++;
                    if (distcj < 0){
                        distcj = -distcj;
                    }
                    a = p[0] - b;
                    if (a < 0){
                        a = -a;
                    }
                    distcj += a;
                    if (distcj < bestd) {
                        a = p[2] - r;
                        if (a < 0){
                            a = -a;
                        }
                        distcj += a;
                        if (distcj < bestd) {
                            bestd = distcj;
                            best = p[3];
                        }
                    }
                }
            }
            if (j >= 0) {
                p = network[Int64(j)];
                distcj = g - p[1]; /* inx key - reverse dif */
                if (distcj >= bestd){
                    j = -1; /* stop iter */
                } else {
                    j--;
                    if (distcj < 0){
                        distcj = -distcj;
                    }
                    a = p[0] - b;
                    if (a < 0){
                        a = -a;
                    }
                    distcj += a;
                    if (distcj < bestd) {
                        a = p[2] - r;
                        if (a < 0){
                            a = -a;
                        }
                        distcj += a;
                        if (distcj < bestd) {
                            bestd = distcj;
                            best = p[3];
                        }
                    }
                }
            }
        }
        return (best);
    }

    public func process():Array<UInt8> {
        // 300ms
        learn();
        unbiasnet();
        inxbuild();
        return colorMap();
    }

    /*
     * Unbias network to give byte values 0..255 and record position i to prepare
     * for sort
     * -----------------------------------------------------------------------------------
     */
    public func unbiasnet():Unit {

        for (i in 0..Int64(netsize)) {
            network[i][0] >>= netbiasshift;
            network[i][1] >>= netbiasshift;
            network[i][2] >>= netbiasshift;
            network[i][3] = Int32(i); /* record colour no */
        }
    }

    /*
     * Move adjacent neurons by precomputed alpha*(1-((i-j)^2/[r]^2)) in
     * radpower[|i-j|]
     * ---------------------------------------------------------------------------------
     */
    protected func alterneigh(rad:Int32, i:Int32, b:Int32, g:Int32, r:Int32):Unit {

        var j:Int32
        var k:Int32
        var locj:Int32
        var hicj:Int32
        var a:Int32
        var m:Int32

        var p:Array<Int32>

        locj = i - rad;
        if (locj < -1){
            locj = -1;
        }
        hicj = i + rad;
        if (hicj > netsize){
            hicj = netsize;
        }

        j = i + 1;
        k = i - 1;
        m = 1;
        while ((j < hicj) || (k > locj)) {
            a = radpower[Int64(m)];
            m++
            if (j < hicj) {
                p = network[Int64(j)];
                j++
                try {
                    p[0] -= (a * (p[0] - b)) / alpharadbias;
                    p[1] -= (a * (p[1] - g)) / alpharadbias;
                    p[2] -= (a * (p[2] - r)) / alpharadbias;
                } catch (e:Exception ) {
                } // prevents 1.3 miscompilation
            }
            if (k > locj) {
                p = network[Int64(k)];
                k--
                try {
                    p[0] -= (a * (p[0] - b)) / alpharadbias;
                    p[1] -= (a * (p[1] - g)) / alpharadbias;
                    p[2] -= (a * (p[2] - r)) / alpharadbias;
                } catch (e:Exception ) {
                }
            }
        }
    }

    /*
     * Move neuron i towards biased (b,g,r) by factor alpha
     * ----------------------------------------------------
     */
    protected func altersingle(alpha:Int32, i:Int32, b:Int32, g:Int32, r:Int32):Unit {

    /* alter hit neuron */
        var n:Array<Int32> = network[Int64(i)];
        n[0] -= (alpha * (n[0] - b)) / initalpha;
        n[1] -= (alpha * (n[1] - g)) / initalpha;
        n[2] -= (alpha * (n[2] - r)) / initalpha;
    }

    /*
     * Search for biased BGR values ----------------------------
     */
    protected func contest(b:Int32, g:Int32, r:Int32):Int32 {

    /* finds closest neuron (min dist) and updates freq */
    /* finds best neuron (min dist-bias) and returns position */
    /* for frequently chosen neurons, freq[i] is high and bias[i] is negative */
    /* bias[i] = gamma*((1/netsize)-freq[i]) */

        var distcj:Int32; var a:Int32; var biasdist:Int32; var betafreqcj:Int32; var bestd:Int32; var bestbiasdcj:Int32
        var bestpos:Int64; var bestbiaspos:Int64
        var n:Array<Int32>;

        bestd = !((Int32(1)) << 31);  //~
        bestbiasdcj = bestd;
        bestpos = -1;
        bestbiaspos = bestpos;

        let netsize64: Int64 = Int64(netsize)

        var n0: Int32
        var n1: Int32
        var n2: Int32
        var shiftcount: Int32 = intbiasshift - netbiasshift
        for (i in 0..netsize64) {
            n = network[i];
            n0 = n[0]
            n1 = n[1]
            n2 = n[2]
            distcj = n0 - b;
            if (distcj < 0){
                distcj = -distcj;
            }
            a = n1 - g;
            if (a < 0){
                a = -a;
            }
            distcj += a;
            a = n2 - r;
            if (a < 0){
                a = -a;
            }
            distcj += a;
            if (distcj < bestd) {
                bestd = distcj;
                bestpos = i;
            }
            biasdist = distcj - (bias[i] >> shiftcount);
            if (biasdist < bestbiasdcj) {
                bestbiasdcj = biasdist;
                bestbiaspos = i;
            }
            betafreqcj = (freq[i] >> betashift);
            freq[i] -= betafreqcj;
            bias[i] += (betafreqcj << gammashift);
        }

        freq[bestpos] += beta;
        bias[bestpos] -= betagamma;
        return Int32(bestbiaspos);
    }
}
