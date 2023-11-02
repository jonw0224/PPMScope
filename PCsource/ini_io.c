/* ==============================================================================
 * Author:  Jonathan Weaver, jonw0224@aim.com
 * E-mail Contact: jonw0224@aim.com
 * Description:  Initialization File Input/Output
 * Version: 1.0
 * Date: 12/22/2011
 * Filename:  ini_io.c, ini_io.h
 *
 * Versions History:
 *      1.0 - 12/22/2011 - Added header to files
 *
 * Copyright (C) 2011 Jonathan Weaver
 *
 * This file is part of PPMScope.
 *
 * PPMScope is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 *
 * ==============================================================================
 */

#include <stdio.h>
#include <stdlib.h>
#include "ini_io.h"

/* States */
#define START       0
#define COMMENT     1
#define GETPARAM    2

/* Debug */
//#define DEBUG

char infoArray[RECCNT][COLCNT][RECLENGTH];
int ind[RECCNT];
int recordNo;

int enumeratePrint()
{
    int i, j;
    i = recordNo;

    /* Debug printing */
    for(j = 0; j < i; j++)
        printf("\'%s\' - \'%s\'\n", infoArray[j][0], infoArray[j][1]);

    printf("\n");

    for(j = 0; j < i; j++)
        printf("%d  \'%s\' - \'%s\'\n", ind[j], infoArray[ind[j]][0], infoArray[ind[j]][1]);

    system("PAUSE");
    /* End debug printing */
    return 0;
}

char* getConfigPar(char* parName)
{
    int k, h, l, j;
    k = 0;
    h = recordNo;
    l = recordNo / 2;
    j = 0;
    while(*parName)
    {
        limitSearch(&l, &k, &h, j, *parName, infoArray, ind);
        j++;
        parName++;
    }
    limitSearch(&l, &k, &h, j, *parName, infoArray, ind);
    return infoArray[ind[k]][1];
}

int setConfigPar(char* parName, char* parValue)
{
    int k, h, l, j;
    k = 0;
    h = recordNo;
    l = recordNo / 2;
    j = 0;
    while(*parName)
    {
        limitSearch(&l, &k, &h, j, *parName, infoArray, ind);
        j++;
        parName++;
    }
    limitSearch(&l, &k, &h, j, *parName, infoArray, ind);
    h = 0;
    while(*parValue)
    {
        infoArray[ind[k]][1][h] = *parValue;
        h++;
        parValue++;
    }
    infoArray[ind[k]][1][h] = '\0';
    return 0;
}

int clearConfig()
{
    int i;

    for(i = 0; i < RECCNT; i++)
    {
          infoArray[i][0][0] = 0;
          ind[i] = 0;
    }
    recordNo = 0;
}

int writeConfigFile(char* fileName)
{
    static FILE *configFile;
    int i;

    configFile = fopen(fileName, "w");
    if(configFile == NULL)
        return 0;

    for(i = 0; i < recordNo; i++)
    {
          if(fprintf(configFile, "%s=%s\n", infoArray[i][0], infoArray[i][1]) < 0)
              return 0;
    }

    fflush(configFile);
    fclose(configFile);

    return 1;
}

int readConfigFile(char* fileName)
{
    static FILE *configFile;
    int state;
    int i, j, c, k, h, l;

    #ifdef DEBUG
    /* to be removed at the end of testing */
    close();
    /* end to be removed */
    #endif

    /**************************************************************************/
    /* Add error checking here, check if file exists! */
    configFile = fopen(fileName, "r");
    if(configFile != NULL)
    {

        i = 0;
        j = 0;
        state = START;
        k = 0;
        h = 0;
        l = 0;

        while((c = getc(configFile)) != EOF)
        {
        switch(state)
        {
        case START:
            if(c=='\'')
            {
                state = COMMENT;
                j = 0;
            }
            else if(c == '=')
            {
                state = GETPARAM;
                infoArray[i][0][j] = '\0';
                limitSearch(&l, &k, &h, j, '\0', infoArray, ind);
                for(h = i; h > k; h--)
                    ind[h] = ind[h-1];
                ind[k] = i;
                j = 0;
            }
            else if((c == '\r') || c == '\n')  ; /* Ignore carrage returns */
            else
            {
                infoArray[i][0][j] = c;
                limitSearch(&l, &k, &h, j, c, infoArray, ind);
                j++;
            }
            break;
        case COMMENT:
            if(c=='\n')
                state = START;
                l = 0;
                h = i+1;
                k = (l+h)/2;
            break;
        case GETPARAM:
            if(c == '\'')
            {
                state = COMMENT;
                infoArray[i][1][j] = '\0';
                j = 0;
                i++;
            }
            else if(c == '\n')
            {
                #ifdef DEBUG
                printf("%d  %d  %d\n\n", l, k, h);
                for(j = 0; j <= i; j++)
                    printf("%d  %d  \'%s\' - \'%s\'\n", j, ind[j], infoArray[ind[j]][0], infoArray[ind[j]][1]);
                printf("\n");
                system("pause");
                #endif
                state = START;
                l = 0;
                h = i+1;
                k = (l+h)/2;
                infoArray[i][1][j] = '\0';
                j = 0;
                i++;
            }
            else if (c == ' ' || c == '\t') ; /* Ignore whitespace */
            else
            {
                infoArray[i][1][j] = c;
                j++;
            }
            break;
        }
        }

        fclose(configFile);
        recordNo = i;
        return 1;
    }
    else
        return 0;
}

int limitSearch(int* l, int* k, int* h, int j, int c,
    char infoArray[RECCNT][COLCNT][RECLENGTH], int ind[RECCNT])
{
    int ll, lh, lc;

    #ifdef DEBUG
    printf("%d - %d - %d - %c\n", *l, *k, *h, c);
    #endif
    /* some problems inserting at the end */
    while((*l < *h) &&
        (infoArray[ind[*k]][0][j] != c))
    {
        if(infoArray[ind[*k]][0][j] > c)
            *h = *k;
        else
            *l = *k+1;
        *k = (*h + *l)/2;
    }
    #ifdef DEBUG
    printf("%d - %d - %d - %c\n", *l, *k, *h, c);
    #endif
    if(*l < *k)
    {
        ll = *l;
        lh = *k;
        while(ll < lh)
        {
            lc = (ll+lh)/2;
            if(infoArray[ind[lc]][0][j] == c)
                lh = lc;
            else
                ll = lc+1;
        }
        *l = (ll + lh) / 2;
        #ifdef DEBUG
        printf("%d - %d - %d - %d - %d\n", *l, *k, *h, ll, lh);
        #endif

        ll = *k;
        lh = *h;
        while(ll < lh)
        {
            lc = (ll+lh)/2;
            if(infoArray[ind[lc]][0][j] == c)
                ll = lc+1;
            else
                lh = lc;
        #ifdef DEBUG
        printf(" loop %d - %d - %d - %d - %d\n", *l, *k, *h, ll, lh);
        #endif
        }
        *h = (ll+lh) / 2;
        *k = (*h + *l) / 2;
        #ifdef DEBUG
        printf("%d - %d - %d - %d - %d\n", *l, *k, *h, ll, lh);
        #endif
    }
    #ifdef DEBUG
    system("pause");
    #endif
    return 0;
}

