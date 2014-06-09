#include <algorithm>
#include <cstdio>
#include <cmath>
#include "mex.h"
#include <vector>
#include <cstring>
using namespace std;
template<class T>
T max(T a, T b)
{
    return a>b? a:b;
}

class Mat2D {
private:
    double * p_data;
    int N_row,N_col;
    
public:
    Mat2D()
    {
        p_data = NULL;
        N_row = 0;
        N_col = 0;
    }
    Mat2D(double * ptr,int _n_row,int _n_col)
    {
        p_data = ptr;
        N_row = _n_row;
        N_col = _n_col;
    }
    int get_index(int i_row, int i_col)
    {
        if(i_row >= N_row || i_col >= N_col)
        {
            printf("try to access (%d %d)\n",i_row,i_col);
            mexErrMsgTxt("invalid index for Mat class in get_idx() ");
        }
        return i_col*N_row + i_row;
    }
    
    int get_N_col()
    {
        return this->N_col;
    }
    int get_N_row()
    {
        return this->N_row;
    }
    double & operator () (const int i_row, const int i_col)
    {
        return (this->p_data[get_index(i_row,i_col)]);
    }
    double & operator () (const int id)
    {
        if(id >= N_row*N_col)
        {
            mexErrMsgTxt("invalid index for Mat class in binary operator () ");
        }
        return this->p_data[id];
    }
    void init_zeros()
    {
        for (int j_col = 0; j_col < N_col; j_col ++) {
            for (int i_row = 0; i_row < N_row; i_row ++) {
                p_data[j_col*N_row + i_row] = 0;
            }
        }
    }
};



void  make_connectivity_at(vector<double> & row_vec,vector<double> & col_vec,vector<double> &value_vec,
        Mat2D &filter, int row_id, int col_id,
        int half_row_width,int half_col_width,int row_connectivity,int col_connectivity)
{
    for (int j_col =  col_id - half_col_width ; j_col <= col_id+half_col_width; j_col++) {
        for (int i_row = row_id - half_row_width; i_row <= row_id+half_row_width; i_row++) {
            if (i_row < 0 || i_row >= row_connectivity || j_col < 0 || j_col >= col_connectivity) {
                continue;
            }
            
            int id_a = col_id * row_connectivity + row_id;
            int id_b = j_col * row_connectivity + i_row;
            //printf("id_a: %d    id_b: %d \n",id_a,id_b);
            int value = filter(i_row - row_id + half_row_width, j_col - col_id + half_col_width );
            row_vec.push_back(id_a+1);
            col_vec.push_back(id_b+1);
            value_vec.push_back(value);
            
        }
    }
}

void  make_connectivity(vector<double> & row_vec,vector<double> & col_vec,vector<double> &value_vec,
        Mat2D &filter, int half_row_width,int half_col_width,int row_connectivity,int col_connectivity)
{
    for (int j_col =0; j_col <col_connectivity; j_col++) {
        for (int i_row=0; i_row < row_connectivity; i_row++) {
            make_connectivity_at(row_vec,col_vec,value_vec,filter,i_row , j_col,half_row_width,half_col_width,row_connectivity,col_connectivity);
        }
    }
}

// input:   1. matrix from 'im = im2col_general'
//          2. patch size [ a,b ]
//          3. image size [a, b]
//          4. connectivity filter F with size of M*N, M and M both are odd
// output:  1. the connectivity matrix
//          1. row vector
//          2. column vector    
//          3. value vector
//          4. size vector

void mexFunction(int nlhs, mxArray *plhs[],int nrhs, const mxArray *prhs[])
{
    double * p_size = mxGetPr(prhs[1]);
    double * img_size = mxGetPr(prhs[2]);
    Mat2D filter = Mat2D(mxGetPr(prhs[3]),mxGetM(prhs[3]),mxGetN(prhs[3]));
    Mat2D mtx_in= Mat2D(mxGetPr(prhs[0]),mxGetM(prhs[0]),mxGetN(prhs[0]));
    
    int half_row_width = 0;
    int half_col_width = 0;
    int row_connectivity = 0;
    int col_connectivity = 0;
    
    
    
    half_row_width = filter.get_N_row()/2;
    half_col_width = filter.get_N_col()/2;
    row_connectivity = img_size[0]-p_size[0]+1;
    col_connectivity = img_size[1] - p_size[1] +1;
    
    
    vector<double> row_vec,col_vec,value_vec;
    make_connectivity(row_vec,col_vec,value_vec,filter,half_row_width,half_col_width,row_connectivity,col_connectivity);
    
    plhs[0] = mxCreateDoubleMatrix(1,row_vec.size(),mxREAL);
    memcpy(mxGetPr(plhs[0]),row_vec.data(),sizeof(double)*row_vec.size());
    
    plhs[1] = mxCreateDoubleMatrix(1,col_vec.size(),mxREAL);
    memcpy(mxGetPr(plhs[1]),col_vec.data(),sizeof(double)*col_vec.size());
    
    plhs[2] = mxCreateDoubleMatrix(1,row_vec.size(),mxREAL);
    memcpy(mxGetPr(plhs[2]),value_vec.data(),sizeof(double)*value_vec.size());
    
    plhs[3] = mxCreateDoubleMatrix(1,2,mxREAL);
    
    
    mxGetPr(plhs[3])[0] = mtx_in.get_N_col();
    mxGetPr(plhs[3])[1] = mtx_in.get_N_col();
}
